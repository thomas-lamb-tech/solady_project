// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library for converting numbers into strings and other string operations.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/LibString.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/LibString.sol)
library LibString {
    /*//////////////////////////////////////////////////////////////
                              CUSTOM ERRORS
    //////////////////////////////////////////////////////////////*/

    error HexLengthInsufficient();

    /*//////////////////////////////////////////////////////////////
                           DECIMAL OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function toString(uint256 value) internal pure returns (string memory str) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit),
            // but we allocate 128 bytes to keep the free memory pointer 32-byte word aliged.
            // We will need 1 32-byte word to store the length,
            // and 3 32-byte words to store a maximum of 78 digits. Total: 32 + 3 * 32 = 128.
            str := add(mload(0x40), 128)
            // Update the free memory pointer to allocate.
            mstore(0x40, str)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 1)
                mstore8(str, add(48, mod(temp, 10)))
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
                // prettier-ignore
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 32)
            // Store the length.
            mstore(str, length)
        }
    }

    /*//////////////////////////////////////////////////////////////
                         HEXADECIMAL OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function toHexString(uint256 value, uint256 length) internal pure returns (string memory str) {
        assembly {
            let start := mload(0x40)
            // We need length * 2 bytes for the digits, 2 bytes for the prefix,
            // and 32 bytes for the length. We add 32 to the total and round down
            // to a multiple of 32. (32 + 2 + 32) = 66.
            str := add(start, and(add(shl(1, length), 66), not(31)))

            // Cache the end to calculate the length later.
            let end := str

            // Allocate the memory.
            mstore(0x40, str)

            let temp := value
            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for {} 1 {} {
                str := sub(str, 2)
                mstore8(add(str, 1), byte(and(temp, 15), "0123456789abcdef"))
                mstore8(str, byte(and(shr(4, temp), 15), "0123456789abcdef"))
                temp := shr(8, temp)
                length := sub(length, 1)
                // prettier-ignore
                if iszero(length) { break }
            }

            if temp {
                // Store the function selector of `HexLengthInsufficient()`.
                mstore(0x00, 0x2194895a)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            // Compute the string's length.
            let strLength := add(sub(end, str), 2)
            // Move the pointer and write the "0x" prefix.
            str := sub(str, 32)
            mstore(str, 0x3078)
            // Move the pointer and write the length.
            str := sub(str, 2)
            mstore(str, strLength)
        }
    }

    function toHexString(uint256 value) internal pure returns (string memory str) {
        assembly {
            let start := mload(0x40)
            // We need 32 bytes for the length, 2 bytes for the prefix,
            // and 64 bytes for the digits.
            // The next multiple of 32 above (32 + 2 + 64) is 128.
            str := add(start, 128)

            // Cache the end to calculate the length later.
            let end := str

            // Allocate the memory.
            mstore(0x40, str)

            let temp := value
            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for {} 1 {} {
                str := sub(str, 2)
                mstore8(add(str, 1), byte(and(temp, 15), "0123456789abcdef"))
                mstore8(str, byte(and(shr(4, temp), 15), "0123456789abcdef"))
                temp := shr(8, temp)
                // prettier-ignore
                if iszero(temp) { break }
            }

            // Compute the string's length.
            let strLength := add(sub(end, str), 2)
            // Move the pointer and write the "0x" prefix.
            str := sub(str, 32)
            mstore(str, 0x3078)
            // Move the pointer and write the length.
            str := sub(str, 2)
            mstore(str, strLength)
        }
    }

    function toHexString(address value) internal pure returns (string memory str) {
        assembly {
            let start := mload(0x40)
            // We need 32 bytes for the length, 2 bytes for the prefix,
            // and 40 bytes for the digits.
            // The next multiple of 32 above (32 + 2 + 40) is 96.
            str := add(start, 96)

            // Allocate the memory.
            mstore(0x40, str)

            let length := 20
            let temp := value
            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for {} 1 {} {
                str := sub(str, 2)
                mstore8(add(str, 1), byte(and(temp, 15), "0123456789abcdef"))
                mstore8(str, byte(and(shr(4, temp), 15), "0123456789abcdef"))
                temp := shr(8, temp)
                length := sub(length, 1)
                // prettier-ignore
                if iszero(length) { break }
            }

            // Move the pointer and write the "0x" prefix.
            str := sub(str, 32)
            mstore(str, 0x3078)
            // Move the pointer and write the length.
            str := sub(str, 2)
            mstore(str, 42)
        }
    }

    /*//////////////////////////////////////////////////////////////
                         OTHER STRING OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function replace(
        string memory subject,
        string memory search,
        string memory replacement
    ) internal pure returns (string memory result) {
        assembly {
            let subjectLength := mload(subject)
            let searchLength := mload(search)
            let replacementLength := mload(replacement)

            // Store the mask for sub-word comparisons in the scratch space.
            mstore(0x00, not(0))
            mstore(0x20, 0)

            subject := add(subject, 0x20)
            search := add(search, 0x20)
            replacement := add(replacement, 0x20)
            result := add(mload(0x40), 0x20)

            let k := 0

            let subjectEnd := add(subject, subjectLength)
            if iszero(gt(searchLength, subjectLength)) {
                let subjectSearchEnd := add(sub(subjectEnd, searchLength), 1)
                // prettier-ignore
                for {} 1 {} {
                    let o := and(searchLength, 31)
                    
                    // Whether the first `searchLength % 32` bytes of
                    // `subject` and `search` matches.
                    switch iszero(and(xor(mload(subject), mload(search)), mload(sub(0x20, o))))
                    case 0 {
                        mstore(add(result, k), mload(subject))
                        k := add(k, 1)
                        subject := add(subject, 1)
                    }
                    default {
                        // Iterate through the rest of `search` and check if any word mismatch.
                        // If any mismatch is detected, `o` is set to the max value of uint256.
                        // prettier-ignore
                        for {} lt(o, searchLength) {} {
                            o := or(add(o, 0x20), sub(eq(mload(add(subject, o)), mload(add(search, o))), 1))
                        }
                        // If `o` is not the max value of uint256, we have a match.
                        if not(o) {
                            // Copy the `replacement` one word at a time.
                            // prettier-ignore
                            for { o := 0 } 1 {} {
                                mstore(add(result, add(k, o)), mload(add(replacement, o)))
                                o := add(o, 0x20)
                                // prettier-ignore
                                if iszero(lt(o, replacementLength)) { break }
                            }
                            k := add(k, replacementLength)
                            subject := add(subject, searchLength)    
                        }
                        if iszero(searchLength) {
                            mstore(add(result, k), mload(subject))
                            k := add(k, 1)
                            subject := add(subject, 1)
                        }
                    }
                    // prettier-ignore
                    if iszero(lt(subject, subjectSearchEnd)) { break }
                }
            }

            let resultRemainder := add(result, k)
            k := add(k, sub(subjectEnd, subject))
            // Copy the rest of the string one word at a time.
            // prettier-ignore
            for {} lt(subject, subjectEnd) {} {
                mstore(resultRemainder, mload(subject))
                resultRemainder := add(resultRemainder, 0x20)
                subject := add(subject, 0x20)
            }
            // Allocate memory for the length and the bytes,
            // rounded up to a multiple of 32.
            mstore(0x40, add(result, and(add(k, 64), not(31))))
            result := sub(result, 0x20)
            mstore(result, k)
        }
    }
}
