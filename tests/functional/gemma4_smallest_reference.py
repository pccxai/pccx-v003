"""Bit-level Python reference for the current Gemma 4 smallest BF16 slice.

The arithmetic intentionally mirrors ``common/bf16/bf16_lane_pkg.sv``.  It is
not a full IEEE-754 BF16 implementation; it is a bit-accurate reference for the
RTL helpers currently checked into this repository.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Iterable, Sequence


BF16_ZERO = 0x0000
BF16_ONE = 0x3F80
BF16_EXP_BIAS = 127


def _u16(value: int) -> int:
    return value & 0xFFFF


def _u32(value: int) -> int:
    return value & 0xFFFFFFFF


def bf16_is_zero(value: int) -> bool:
    return (_u16(value) & 0x7FFF) == 0


def bf16_neg(value: int) -> int:
    value = _u16(value)
    if bf16_is_zero(value):
        return BF16_ZERO
    return value ^ 0x8000


def bf16_pack(sign: int, exponent: int, mantissa_with_hidden: int) -> int:
    if exponent <= 0:
        return BF16_ZERO
    exponent_clamped = 0xFE if exponent >= 255 else exponent & 0xFF
    return ((sign & 1) << 15) | (exponent_clamped << 7) | (mantissa_with_hidden & 0x7F)


def bf16_mul(lhs: int, rhs: int) -> int:
    lhs = _u16(lhs)
    rhs = _u16(rhs)
    if bf16_is_zero(lhs) or bf16_is_zero(rhs):
        return BF16_ZERO

    sign = ((lhs >> 15) ^ (rhs >> 15)) & 1
    lhs_mantissa = 0x80 | (lhs & 0x7F)
    rhs_mantissa = 0x80 | (rhs & 0x7F)
    product = lhs_mantissa * rhs_mantissa
    exponent = ((lhs >> 7) & 0xFF) + ((rhs >> 7) & 0xFF) - BF16_EXP_BIAS

    if product & 0x8000:
        normalized_mantissa = (product >> 7) & 0xFF
        exponent += 1
    else:
        normalized_mantissa = (product >> 6) & 0xFF

    return bf16_pack(sign, exponent, normalized_mantissa)


def bf16_add(lhs: int, rhs: int) -> int:
    lhs = _u16(lhs)
    rhs = _u16(rhs)
    if bf16_is_zero(lhs):
        return rhs
    if bf16_is_zero(rhs):
        return lhs

    lhs_exp = (lhs >> 7) & 0xFF
    rhs_exp = (rhs >> 7) & 0xFF
    lhs_mantissa = -(0x80 | (lhs & 0x7F)) if (lhs & 0x8000) else (0x80 | (lhs & 0x7F))
    rhs_mantissa = -(0x80 | (rhs & 0x7F)) if (rhs & 0x8000) else (0x80 | (rhs & 0x7F))

    if lhs_exp > rhs_exp:
        result_exp = lhs_exp
        rhs_mantissa = 0 if (lhs_exp - rhs_exp) >= 8 else rhs_mantissa >> (lhs_exp - rhs_exp)
    else:
        result_exp = rhs_exp
        lhs_mantissa = 0 if (rhs_exp - lhs_exp) >= 8 else lhs_mantissa >> (rhs_exp - lhs_exp)

    mantissa_sum = lhs_mantissa + rhs_mantissa
    if mantissa_sum == 0:
        return BF16_ZERO

    result_sign = mantissa_sum < 0
    mantissa_abs = -mantissa_sum if result_sign else mantissa_sum

    if mantissa_abs & 0x100:
        mantissa_abs >>= 1
        result_exp += 1

    for _ in range(8):
        if not (mantissa_abs & 0x80) and result_exp > 0:
            mantissa_abs <<= 1
            result_exp -= 1

    return bf16_pack(1 if result_sign else 0, result_exp, mantissa_abs & 0xFF)


def bf16_sub(lhs: int, rhs: int) -> int:
    return bf16_add(lhs, bf16_neg(rhs))


def bf16_relu(value: int) -> int:
    value = _u16(value)
    return BF16_ZERO if (value & 0x8000) else value


@dataclass(frozen=True)
class TensorPacket:
    """One tensor-stream beat represented lane-low first."""

    lanes: tuple[int, ...]
    keep: int
    user: int = 0
    last: bool = True

    @property
    def data_w(self) -> int:
        return len(self.lanes) * 16

    @property
    def keep_w(self) -> int:
        return len(self.lanes) * 2

    def data_word(self) -> int:
        word = 0
        for lane, value in enumerate(self.lanes):
            word |= _u16(value) << (lane * 16)
        return word


@dataclass(frozen=True)
class DecodeResult:
    rms: TensorPacket
    rope: TensorPacket
    attention: TensorPacket
    mlp: TensorPacket
    token: int
    sequence_id: int
    last: bool


def full_keep(lane_count: int) -> int:
    return (1 << (lane_count * 2)) - 1


def packet_from_lanes(
    lanes: Iterable[int],
    *,
    keep: int | None = None,
    user: int = 0,
    last: bool = True,
) -> TensorPacket:
    lane_tuple = tuple(_u16(lane) for lane in lanes)
    if keep is None:
        keep = full_keep(len(lane_tuple))
    return TensorPacket(lane_tuple, keep & full_keep(len(lane_tuple)), _u32(user), bool(last))


def lane_active(keep: int, lane: int) -> bool:
    low_byte = lane * 2
    return bool((keep >> low_byte) & 1) and bool((keep >> (low_byte + 1)) & 1)


def _binary_lane_keep(lhs_keep: int, rhs_keep: int, lane_count: int) -> int:
    keep = 0
    for lane in range(lane_count):
        if lane_active(lhs_keep, lane) and lane_active(rhs_keep, lane):
            keep |= 0b11 << (lane * 2)
    return keep


def _ternary_lane_keep(first_keep: int, second_keep: int, third_keep: int, lane_count: int) -> int:
    keep = 0
    for lane in range(lane_count):
        if lane_active(first_keep, lane) and lane_active(second_keep, lane) and lane_active(third_keep, lane):
            keep |= 0b11 << (lane * 2)
    return keep


def rmsnorm(input_packet: TensorPacket, weight_packet: TensorPacket, inv_rms: int = BF16_ONE) -> TensorPacket:
    if len(input_packet.lanes) != len(weight_packet.lanes):
        raise ValueError("input and weight packets must have the same lane count")

    lanes = []
    for lane, (input_lane, weight_lane) in enumerate(zip(input_packet.lanes, weight_packet.lanes)):
        if lane_active(input_packet.keep, lane) and lane_active(weight_packet.keep, lane):
            scaled = bf16_mul(input_lane, inv_rms)
            lanes.append(bf16_mul(scaled, weight_lane))
        else:
            lanes.append(BF16_ZERO)
    return TensorPacket(
        tuple(lanes),
        _binary_lane_keep(input_packet.keep, weight_packet.keep, len(lanes)),
        input_packet.user,
        input_packet.last and weight_packet.last,
    )


def attention(query_packet: TensorPacket, key_packet: TensorPacket, value_packet: TensorPacket) -> TensorPacket:
    if not (len(query_packet.lanes) == len(key_packet.lanes) == len(value_packet.lanes)):
        raise ValueError("query, key, and value packets must have the same lane count")

    lanes = []
    for lane, (query_lane, key_lane, value_lane) in enumerate(
        zip(query_packet.lanes, key_packet.lanes, value_packet.lanes)
    ):
        if (
            lane_active(query_packet.keep, lane)
            and lane_active(key_packet.keep, lane)
            and lane_active(value_packet.keep, lane)
        ):
            lanes.append(bf16_mul(bf16_mul(query_lane, key_lane), value_lane))
        else:
            lanes.append(BF16_ZERO)
    return TensorPacket(
        tuple(lanes),
        _ternary_lane_keep(query_packet.keep, key_packet.keep, value_packet.keep, len(lanes)),
        query_packet.user,
        query_packet.last and key_packet.last and value_packet.last,
    )


def mlp(activation_packet: TensorPacket, weight_packet: TensorPacket) -> TensorPacket:
    if len(activation_packet.lanes) != len(weight_packet.lanes):
        raise ValueError("activation and weight packets must have the same lane count")

    lanes = []
    for lane, (activation_lane, weight_lane) in enumerate(zip(activation_packet.lanes, weight_packet.lanes)):
        if lane_active(activation_packet.keep, lane) and lane_active(weight_packet.keep, lane):
            lanes.append(bf16_relu(bf16_mul(activation_lane, weight_lane)))
        else:
            lanes.append(BF16_ZERO)
    return TensorPacket(
        tuple(lanes),
        _binary_lane_keep(activation_packet.keep, weight_packet.keep, len(lanes)),
        activation_packet.user,
        activation_packet.last and weight_packet.last,
    )


def rope(input_packet: TensorPacket, rotation_packet: TensorPacket) -> TensorPacket:
    if len(input_packet.lanes) != len(rotation_packet.lanes):
        raise ValueError("input and rotation packets must have the same lane count")
    if len(input_packet.lanes) % 2:
        raise ValueError("RoPE packet lane count must be even")

    lanes = [BF16_ZERO] * len(input_packet.lanes)
    keep = 0
    for pair in range(len(input_packet.lanes) // 2):
        even_lane = pair * 2
        odd_lane = even_lane + 1
        if (
            lane_active(input_packet.keep, even_lane)
            and lane_active(input_packet.keep, odd_lane)
            and lane_active(rotation_packet.keep, even_lane)
            and lane_active(rotation_packet.keep, odd_lane)
        ):
            x_even = input_packet.lanes[even_lane]
            x_odd = input_packet.lanes[odd_lane]
            cos_lane = rotation_packet.lanes[even_lane]
            sin_lane = rotation_packet.lanes[odd_lane]
            lanes[even_lane] = bf16_sub(bf16_mul(x_even, cos_lane), bf16_mul(x_odd, sin_lane))
            lanes[odd_lane] = bf16_add(bf16_mul(x_even, sin_lane), bf16_mul(x_odd, cos_lane))
            keep |= 0b1111 << (even_lane * 2)

    return TensorPacket(tuple(lanes), keep, input_packet.user, input_packet.last and rotation_packet.last)


def decode_one_token(
    embedding: TensorPacket,
    rms_weight: TensorPacket,
    rotation: TensorPacket,
    kv_read: TensorPacket,
    value: TensorPacket,
    mlp_weight: TensorPacket,
    *,
    inv_rms: int = BF16_ONE,
    token_w: int = 32,
) -> DecodeResult:
    rms_packet = rmsnorm(embedding, rms_weight, inv_rms)
    rope_packet = rope(rms_packet, rotation)
    attention_packet = attention(rope_packet, kv_read, value)
    mlp_packet = mlp(attention_packet, mlp_weight)
    token_mask = (1 << token_w) - 1
    return DecodeResult(
        rms=rms_packet,
        rope=rope_packet,
        attention=attention_packet,
        mlp=mlp_packet,
        token=mlp_packet.data_word() & token_mask,
        sequence_id=embedding.user,
        last=mlp_packet.last,
    )


def functional_crosscheck_vectors() -> dict[str, TensorPacket]:
    lanes = [0x3F80, 0x4000, 0xBF80, 0x3F00]

    rms_input = packet_from_lanes(lanes, user=0x00001001)
    rms_weight = packet_from_lanes([0x3F80, 0x3F00, 0xBF80, 0x4000], user=0x00001002)

    attn_query = packet_from_lanes(lanes, user=0x00002001)
    attn_key = packet_from_lanes([0x3F80, 0x3F00, 0xBF80, 0x4000], user=0x00002002)
    attn_value = packet_from_lanes([0x4000, 0xBF80, 0x3F00, 0x3F80], user=0x00002003)

    mlp_activation = packet_from_lanes([0x4000, 0xC000, 0x3F00, 0xBF00], user=0x00003001)
    mlp_weight = packet_from_lanes([0x3F00, 0x3F00, 0x4000, 0x4000], user=0x00003002)

    return {
        "rms_input": rms_input,
        "rms_weight": rms_weight,
        "rms_expected": rmsnorm(rms_input, rms_weight),
        "attn_query": attn_query,
        "attn_key": attn_key,
        "attn_value": attn_value,
        "attn_expected": attention(attn_query, attn_key, attn_value),
        "mlp_activation": mlp_activation,
        "mlp_weight": mlp_weight,
        "mlp_expected": mlp(mlp_activation, mlp_weight),
    }


def smallest_decode_fixture() -> DecodeResult:
    four_ones = packet_from_lanes([BF16_ONE] * 4, user=0x0000002A)
    rotation = packet_from_lanes([BF16_ONE, BF16_ZERO, BF16_ONE, BF16_ZERO], user=0x0000002A)
    kv_read = packet_from_lanes([BF16_ONE] * 4, user=0x00000003)
    return decode_one_token(
        embedding=four_ones,
        rms_weight=four_ones,
        rotation=rotation,
        kv_read=kv_read,
        value=four_ones,
        mlp_weight=four_ones,
    )


def deterministic_packet(lane_count: int, *, user: int = 0, offset: int = 0) -> TensorPacket:
    values: Sequence[int] = (0x3F80, 0x4000, 0x3F00, 0xBF80, 0xBF00, 0x0000)
    lanes = [values[(offset + lane) % len(values)] for lane in range(lane_count)]
    return packet_from_lanes(lanes, user=user)
