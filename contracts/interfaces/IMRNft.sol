// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IMrNft is IERC165, IERC721, IAccessControl {
    function mintItem(
        address player,
        string memory axeId,
        string memory axeType
    ) external;

    function axeIdToTokenId(
        string memory axeId
    ) external view returns (uint256);
}
