import unittest

from gemma4_smallest_reference import (
    BF16_ONE,
    BF16_ZERO,
    attention,
    bf16_add,
    bf16_mul,
    bf16_relu,
    functional_crosscheck_vectors,
    mlp,
    packet_from_lanes,
    rmsnorm,
    smallest_decode_fixture,
)


class Gemma4SmallestReferenceTest(unittest.TestCase):
    def test_bf16_helpers_match_current_rtl_examples(self):
        self.assertEqual(bf16_mul(0x3F80, 0x3F80), 0x3F80)
        self.assertEqual(bf16_mul(0x4000, 0x3F00), 0x3F80)
        self.assertEqual(bf16_mul(0xBF80, 0xBF80), 0x3F80)
        self.assertEqual(bf16_add(0x3F80, 0xBF80), BF16_ZERO)
        self.assertEqual(bf16_relu(0xBF80), BF16_ZERO)

    def test_attention_mlp_rmsnorm_vectors_are_bit_exact(self):
        vectors = functional_crosscheck_vectors()
        self.assertEqual(
            rmsnorm(vectors["rms_input"], vectors["rms_weight"]),
            vectors["rms_expected"],
        )
        self.assertEqual(
            attention(vectors["attn_query"], vectors["attn_key"], vectors["attn_value"]),
            vectors["attn_expected"],
        )
        self.assertEqual(
            mlp(vectors["mlp_activation"], vectors["mlp_weight"]),
            vectors["mlp_expected"],
        )
        self.assertEqual(vectors["rms_expected"].data_word(), 0x3F803F803F803F80)
        self.assertEqual(vectors["attn_expected"].data_word(), 0x3F803F00BF804000)
        self.assertEqual(vectors["mlp_expected"].data_word(), 0x00003F8000003F80)

    def test_masked_lanes_clear_data_and_keep(self):
        input_packet = packet_from_lanes([BF16_ONE, BF16_ONE], keep=0b0011)
        weight_packet = packet_from_lanes([BF16_ONE, BF16_ONE], keep=0b1111)
        result = rmsnorm(input_packet, weight_packet)
        self.assertEqual(result.keep, 0b0011)
        self.assertEqual(result.lanes, (BF16_ONE, BF16_ZERO))

    def test_smallest_decode_fixture_matches_token_readback_shape(self):
        result = smallest_decode_fixture()
        self.assertEqual(result.rms.data_word(), 0x3F803F803F803F80)
        self.assertEqual(result.attention.data_word(), 0x3F803F803F803F80)
        self.assertEqual(result.mlp.data_word(), 0x3F803F803F803F80)
        self.assertEqual(result.token, 0x3F803F80)
        self.assertEqual(result.sequence_id, 0x0000002A)
        self.assertTrue(result.last)


if __name__ == "__main__":
    unittest.main()
