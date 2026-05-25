"""Quantization helpers for the Gemma 4 functional model."""

from __future__ import annotations

from dataclasses import dataclass

import numpy as np

from gemma4_functional_model import Array, Gemma4Weights, map_weights


@dataclass(frozen=True)
class QuantizedTensor:
    values: Array
    scale: Array
    bits: int
    axis: int | None


def float32_to_bf16(values: Array) -> Array:
    source = np.asarray(values, dtype=np.float32)
    bits = source.view(np.uint32)
    rounding_bias = np.uint32(0x7FFF) + ((bits >> np.uint32(16)) & np.uint32(1))
    return ((bits + rounding_bias) >> np.uint32(16)).astype(np.uint16)


def bf16_to_float32(values: Array) -> Array:
    upper = np.asarray(values, dtype=np.uint16).astype(np.uint32) << np.uint32(16)
    return upper.view(np.float32)


def fake_quantize_bf16(values: Array) -> Array:
    return bf16_to_float32(float32_to_bf16(values)).astype(np.float32)


def _qrange(bits: int) -> tuple[int, int]:
    if bits != 4:
        raise ValueError("only INT4 is supported")
    return -(2 ** (bits - 1)), (2 ** (bits - 1)) - 1


def quantize_symmetric(values: Array, *, bits: int, axis: int | None = None) -> QuantizedTensor:
    qmin, qmax = _qrange(bits)
    source = np.asarray(values, dtype=np.float32)
    max_abs = np.max(np.abs(source), axis=axis, keepdims=True)
    scale = np.where(max_abs == 0.0, 1.0, max_abs / qmax).astype(np.float32)
    quantized = np.rint(source / scale)
    quantized = np.clip(quantized, qmin, qmax).astype(np.int8)
    if axis is None:
        scale_out = np.asarray(scale.reshape(()), dtype=np.float32)
    else:
        scale_out = np.squeeze(scale, axis=axis).astype(np.float32)
    return QuantizedTensor(values=quantized, scale=scale_out, bits=bits, axis=axis)


def dequantize_symmetric(quantized: QuantizedTensor) -> Array:
    scale = quantized.scale
    if quantized.axis is not None:
        scale = np.expand_dims(scale, axis=quantized.axis)
    return (quantized.values.astype(np.float32) * scale.astype(np.float32)).astype(np.float32)


def fake_quantize_symmetric(values: Array, *, bits: int, axis: int | None = None) -> Array:
    return dequantize_symmetric(quantize_symmetric(values, bits=bits, axis=axis))


def pack_int4(values: Array) -> Array:
    quantized = np.asarray(values, dtype=np.int8).reshape(-1)
    if np.any(quantized < -8) or np.any(quantized > 7):
        raise ValueError("INT4 values must be in [-8, 7]")
    if quantized.size % 2:
        quantized = np.concatenate([quantized, np.zeros((1,), dtype=np.int8)])
    nibbles = (quantized.astype(np.uint8) & 0x0F).reshape(-1, 2)
    return (nibbles[:, 0] | (nibbles[:, 1] << 4)).astype(np.uint8)


def unpack_int4(packed: Array, *, count: int | None = None) -> Array:
    data = np.asarray(packed, dtype=np.uint8).reshape(-1)
    low = data & 0x0F
    high = (data >> 4) & 0x0F
    values = np.empty((data.size * 2,), dtype=np.int8)
    values[0::2] = low.astype(np.int8)
    values[1::2] = high.astype(np.int8)
    values = np.where(values >= 8, values - 16, values).astype(np.int8)
    if count is not None:
        values = values[:count]
    return values


def quantize_weights_bf16(weights: Gemma4Weights) -> Gemma4Weights:
    return map_weights(weights, fake_quantize_bf16)


def quantize_weights_int4(weights: Gemma4Weights) -> Gemma4Weights:
    def quantize_array(values: Array) -> Array:
        axis = 0 if np.asarray(values).ndim > 1 else None
        return fake_quantize_symmetric(values, bits=4, axis=axis)

    return map_weights(weights, quantize_array)
