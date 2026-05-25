"""Small NumPy reference for Gemma 4-family functional checks.

This is a deterministic fixture model for software/RTL cross-checks.  It does
not encode a measured board runtime or a full production model configuration.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Callable, Sequence

import numpy as np


Array = np.ndarray


@dataclass(frozen=True)
class Gemma4Config:
    vocab_size: int
    hidden_size: int
    num_layers: int
    num_heads: int
    num_kv_heads: int
    intermediate_size: int
    max_position_embeddings: int = 4096
    rope_theta: float = 10000.0
    rms_norm_eps: float = 1e-6

    @property
    def head_dim(self) -> int:
        if self.hidden_size % self.num_heads != 0:
            raise ValueError("hidden_size must be divisible by num_heads")
        return self.hidden_size // self.num_heads


@dataclass(frozen=True)
class Gemma4LayerWeights:
    attn_norm: Array
    ffn_norm: Array
    wq: Array
    wk: Array
    wv: Array
    wo: Array
    w_gate: Array
    w_up: Array
    w_down: Array


@dataclass(frozen=True)
class Gemma4Weights:
    token_embedding: Array
    layers: Sequence[Gemma4LayerWeights]
    final_norm: Array
    lm_head: Array


def tiny_config() -> Gemma4Config:
    return Gemma4Config(
        vocab_size=32,
        hidden_size=16,
        num_layers=2,
        num_heads=4,
        num_kv_heads=2,
        intermediate_size=32,
        max_position_embeddings=64,
    )


def rms_norm(x: Array, weight: Array, eps: float) -> Array:
    variance = np.mean(np.square(x, dtype=np.float32), axis=-1, keepdims=True)
    return (x * np.reciprocal(np.sqrt(variance + eps)) * weight).astype(np.float32)


def silu(x: Array) -> Array:
    return (x / (1.0 + np.exp(-x))).astype(np.float32)


def _rope_tables(seq_len: int, head_dim: int, theta: float) -> tuple[Array, Array]:
    if head_dim % 2:
        raise ValueError("head_dim must be even for RoPE")

    positions = np.arange(seq_len, dtype=np.float32)[:, None]
    dims = np.arange(0, head_dim, 2, dtype=np.float32)[None, :]
    inv_freq = 1.0 / (theta ** (dims / head_dim))
    angles = positions * inv_freq
    return np.cos(angles).astype(np.float32), np.sin(angles).astype(np.float32)


def apply_rope(x: Array, cos: Array, sin: Array) -> Array:
    x_even = x[..., 0::2]
    x_odd = x[..., 1::2]
    cos = cos[:, None, :]
    sin = sin[:, None, :]
    out = np.empty_like(x, dtype=np.float32)
    out[..., 0::2] = x_even * cos - x_odd * sin
    out[..., 1::2] = x_even * sin + x_odd * cos
    return out


def _linear(x: Array, weight: Array) -> Array:
    return np.matmul(x, weight).astype(np.float32)


def _split_heads(x: Array, heads: int) -> Array:
    seq_len, hidden = x.shape
    if hidden % heads:
        raise ValueError("projection size must be divisible by heads")
    return x.reshape(seq_len, heads, hidden // heads)


def _repeat_kv(x: Array, num_heads: int) -> Array:
    repeats = num_heads // x.shape[1]
    if repeats * x.shape[1] != num_heads:
        raise ValueError("num_heads must be a multiple of num_kv_heads")
    return np.repeat(x, repeats, axis=1)


def causal_attention(q: Array, k: Array, v: Array) -> Array:
    scale = np.float32(1.0 / np.sqrt(q.shape[-1]))
    scores = np.einsum("qhd,khd->hqk", q, k, optimize=True) * scale
    mask = np.triu(np.ones((q.shape[0], k.shape[0]), dtype=bool), k=1)
    scores = np.where(mask[None, :, :], np.float32(-1.0e30), scores)
    scores = scores - np.max(scores, axis=-1, keepdims=True)
    probs = np.exp(scores).astype(np.float32)
    probs = probs / np.sum(probs, axis=-1, keepdims=True)
    context = np.einsum("hqk,khd->qhd", probs, v, optimize=True)
    return context.reshape(q.shape[0], -1).astype(np.float32)


def forward(config: Gemma4Config, weights: Gemma4Weights, input_ids: Array) -> Array:
    ids = np.asarray(input_ids, dtype=np.int64)
    if ids.ndim != 1:
        raise ValueError("input_ids must be a 1-D sequence")
    if ids.size > config.max_position_embeddings:
        raise ValueError("sequence exceeds max_position_embeddings")

    x = weights.token_embedding[ids].astype(np.float32)
    cos, sin = _rope_tables(ids.size, config.head_dim, config.rope_theta)

    for layer in weights.layers:
        attn_in = rms_norm(x, layer.attn_norm, config.rms_norm_eps)
        q = apply_rope(_split_heads(_linear(attn_in, layer.wq), config.num_heads), cos, sin)
        k = apply_rope(_split_heads(_linear(attn_in, layer.wk), config.num_kv_heads), cos, sin)
        v = _split_heads(_linear(attn_in, layer.wv), config.num_kv_heads)
        attn = causal_attention(q, _repeat_kv(k, config.num_heads), _repeat_kv(v, config.num_heads))
        x = (x + _linear(attn, layer.wo)).astype(np.float32)

        ffn_in = rms_norm(x, layer.ffn_norm, config.rms_norm_eps)
        gated = silu(_linear(ffn_in, layer.w_gate)) * _linear(ffn_in, layer.w_up)
        x = (x + _linear(gated, layer.w_down)).astype(np.float32)

    x = rms_norm(x, weights.final_norm, config.rms_norm_eps)
    return _linear(x, weights.lm_head)


def map_weights(weights: Gemma4Weights, fn: Callable[[Array], Array]) -> Gemma4Weights:
    layers = []
    for layer in weights.layers:
        layers.append(
            Gemma4LayerWeights(
                attn_norm=fn(layer.attn_norm),
                ffn_norm=fn(layer.ffn_norm),
                wq=fn(layer.wq),
                wk=fn(layer.wk),
                wv=fn(layer.wv),
                wo=fn(layer.wo),
                w_gate=fn(layer.w_gate),
                w_up=fn(layer.w_up),
                w_down=fn(layer.w_down),
            )
        )

    return Gemma4Weights(
        token_embedding=fn(weights.token_embedding),
        layers=tuple(layers),
        final_norm=fn(weights.final_norm),
        lm_head=fn(weights.lm_head),
    )


def make_tiny_random_weights(config: Gemma4Config, seed: int = 7) -> Gemma4Weights:
    rng = np.random.default_rng(seed)

    def normal(shape: tuple[int, ...]) -> Array:
        return (rng.standard_normal(shape).astype(np.float32) * 0.02).astype(np.float32)

    kv_hidden = config.num_kv_heads * config.head_dim
    layers = []
    for _ in range(config.num_layers):
        layers.append(
            Gemma4LayerWeights(
                attn_norm=np.ones((config.hidden_size,), dtype=np.float32),
                ffn_norm=np.ones((config.hidden_size,), dtype=np.float32),
                wq=normal((config.hidden_size, config.hidden_size)),
                wk=normal((config.hidden_size, kv_hidden)),
                wv=normal((config.hidden_size, kv_hidden)),
                wo=normal((config.hidden_size, config.hidden_size)),
                w_gate=normal((config.hidden_size, config.intermediate_size)),
                w_up=normal((config.hidden_size, config.intermediate_size)),
                w_down=normal((config.intermediate_size, config.hidden_size)),
            )
        )

    return Gemma4Weights(
        token_embedding=normal((config.vocab_size, config.hidden_size)),
        layers=tuple(layers),
        final_norm=np.ones((config.hidden_size,), dtype=np.float32),
        lm_head=normal((config.hidden_size, config.vocab_size)),
    )
