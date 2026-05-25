import unittest

import numpy as np

from gemma4_functional_model import forward, make_tiny_random_weights, tiny_config
from gemma4_quantization import (
    bf16_to_float32,
    dequantize_symmetric,
    float32_to_bf16,
    pack_int4,
    quantize_symmetric,
    quantize_weights_bf16,
    quantize_weights_int4,
    unpack_int4,
)


class Gemma4FunctionalModelTest(unittest.TestCase):
    def test_tiny_forward_shape(self):
        config = tiny_config()
        weights = make_tiny_random_weights(config)
        logits = forward(config, weights, np.array([1, 2, 3, 4], dtype=np.int64))
        self.assertEqual(logits.shape, (4, config.vocab_size))
        self.assertTrue(np.isfinite(logits).all())

    def test_bf16_round_trip_uses_expected_top_bits(self):
        values = np.array([0.0, 1.0, -2.0, 0.5], dtype=np.float32)
        bf16 = float32_to_bf16(values)
        self.assertEqual(bf16.dtype, np.uint16)
        expected = np.array([0x0000, 0x3F80, 0xC000, 0x3F00], dtype=np.uint16)
        np.testing.assert_array_equal(bf16, expected)
        np.testing.assert_allclose(bf16_to_float32(bf16), values)

    def test_bf16_quantized_weights_keep_forward_finite(self):
        config = tiny_config()
        weights = make_tiny_random_weights(config)
        quantized = quantize_weights_bf16(weights)
        logits = forward(config, quantized, np.array([1, 2, 3, 4], dtype=np.int64))
        self.assertEqual(logits.shape, (4, config.vocab_size))
        self.assertTrue(np.isfinite(logits).all())

    def test_int4_symmetric_quantize_dequantize(self):
        values = np.array([[-1.0, 0.0, 0.5], [1.0, -0.25, 0.25]], dtype=np.float32)
        quantized = quantize_symmetric(values, bits=4, axis=0)
        restored = dequantize_symmetric(quantized)
        self.assertEqual(quantized.values.dtype, np.int8)
        self.assertEqual(restored.shape, values.shape)
        self.assertLess(np.max(np.abs(values - restored)), 0.15)

    def test_int4_pack_round_trip(self):
        values = np.array([-8, -3, 0, 7, 6], dtype=np.int8)
        packed = pack_int4(values)
        unpacked = unpack_int4(packed, count=values.size)
        np.testing.assert_array_equal(unpacked, values)

    def test_int4_quantized_weights_keep_forward_finite(self):
        config = tiny_config()
        weights = make_tiny_random_weights(config)
        quantized = quantize_weights_int4(weights)
        logits = forward(config, quantized, np.array([1, 2, 3, 4], dtype=np.int64))
        self.assertEqual(logits.shape, (4, config.vocab_size))
        self.assertTrue(np.isfinite(logits).all())


if __name__ == "__main__":
    unittest.main()
