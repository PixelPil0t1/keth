from starkware.cairo.common.cairo_builtins import BitwiseBuiltin
from cairo_core.maths import (
    sign,
    assert_uint256_le,
    pow2,
    pow256,
    felt252_to_bytes_le,
    felt252_to_bytes_be,
)
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.alloc import alloc

func test__assert_uint256_le{range_check_ptr}() {
    alloc_locals;
    let (a_ptr) = alloc();
    let (b_ptr) = alloc();
    %{
        segments.write_arg(ids.a_ptr, program_input["a"])
        segments.write_arg(ids.b_ptr, program_input["b"])
    %}
    assert_uint256_le([cast(a_ptr, Uint256*)], [cast(b_ptr, Uint256*)]);

    return ();
}

func test__felt252_to_bytes_le{range_check_ptr, bitwise_ptr: BitwiseBuiltin*}(
    value: felt, len: felt
) -> felt* {
    alloc_locals;
    let (dst) = alloc();
    let res = felt252_to_bytes_le(value, len, dst);
    return dst;
}

func test__felt252_to_bytes_be{range_check_ptr, bitwise_ptr: BitwiseBuiltin*}(
    value: felt, len: felt
) -> felt* {
    alloc_locals;
    let (dst) = alloc();
    let res = felt252_to_bytes_be(value, len, dst);
    return dst;
}
