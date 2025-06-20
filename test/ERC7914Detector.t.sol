// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import {Test} from "forge-std/Test.sol";
import {ERC7914Detector} from "../src/ERC7914Detector.sol";
import {IERC7914} from "../src/interfaces/IERC7914.sol";
import {ICalibur} from "../src/interfaces/ICalibur.sol";
import {CaliburEntryUtils} from "./util/CaliburEntryUtils.sol";
import {MockWrongReturnTypeContract} from "./mock/MockWrongReturnTypeContract.sol";
import {MockNonERC7914Contract} from "./mock/MockNonERC7914Contract.sol";

contract ERC7914DetectorTest is Test {
    ICalibur public calibur;
    uint256 signerPrivateKey = 0xa11ce;
    address signer = vm.addr(signerPrivateKey);

    ERC7914Detector public detector;
    ICalibur public signerAccount;
    MockWrongReturnTypeContract public wrongReturnTypeContract;
    MockNonERC7914Contract public nonERC7914Contract;

    function setUp() public {
        CaliburEntryUtils caliburEntryUtils = new CaliburEntryUtils();
        calibur = ICalibur(create2(caliburEntryUtils.getCaliburEntryCode(), bytes32(0)));
        _delegate(signer, address(calibur));
        signerAccount = ICalibur(signer);

        detector = new ERC7914Detector(address(calibur));
        wrongReturnTypeContract = new MockWrongReturnTypeContract();
        nonERC7914Contract = new MockNonERC7914Contract();
    }

    function create2(bytes memory initcode, bytes32 salt) internal returns (address contractAddress) {
        assembly {
            contractAddress := create2(0, add(initcode, 32), mload(initcode), salt)
            if iszero(contractAddress) {
                let ptr := mload(0x40)
                let errorSize := returndatasize()
                returndatacopy(ptr, 0, errorSize)
                revert(ptr, errorSize)
            }
        }
    }

    function _delegate(address _signer, address _implementation) internal {
        vm.etch(_signer, bytes.concat(hex"ef0100", abi.encodePacked(_implementation)));
        require(_signer.code.length > 0, "signer not delegated");
    }

    /// @notice Test ERC7914 detection functionality across different contract types
    function test_erc7914Detection() public {
        // Test with non-ERC7914 contract
        bool hasSupport = detector.hasERC7914Support(address(nonERC7914Contract));
        assertFalse(hasSupport, "Non-ERC7914 contract should not be detected");

        // Test with EOA
        address eoa = makeAddr("testEOA");
        hasSupport = detector.hasERC7914Support(eoa);
        assertFalse(hasSupport, "EOA should not support ERC7914");

        // Test with ERC7914-supporting contract (calibur address matches signerAccount)
        hasSupport = detector.hasERC7914Support(address(signerAccount));
        assertTrue(hasSupport, "ERC7914-supporting contract should be detected");

        // Test with ERC7914-supporting contract (calibur address does not match signerAccount)
        detector = new ERC7914Detector(address(nonERC7914Contract));
        hasSupport = detector.hasERC7914Support(address(signerAccount));
        assertTrue(hasSupport, "ERC7914-supporting contract should be detected");
    }

    /// @notice Test that contracts with transferFromNative function but wrong return type are not detected as ERC7914
    function test_erc7914DetectionWrongReturnType() public {
        // Test with contract that has transferFromNative function but returns uint256 instead of bool
        bool hasSupport = detector.hasERC7914Support(address(wrongReturnTypeContract));
        assertFalse(hasSupport, "Contract with wrong return type should not be detected as ERC7914");
    }
}
