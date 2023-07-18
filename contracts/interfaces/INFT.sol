// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface INFT is IERC165, IERC721, IAccessControl {
    function bulkMint(
        address[] memory recipients,
        uint256[] memory tierIds,
        uint256[] memory tierSizes
    ) external;
}
