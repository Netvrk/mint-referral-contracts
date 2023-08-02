// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import "hardhat/console.sol";

contract RootNft is AccessControl, ERC721 {
    mapping(uint256 => string) private _tokenURIs;
    bytes32 public constant PREDICATE_ROLE = keccak256("PREDICATE_ROLE");
    string public baseURI;
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory url_
    ) ERC721(name_, symbol_) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PREDICATE_ROLE, msg.sender);
        baseURI = url_;
    }

    function mint(
        address user,
        uint256 tokenId
    ) external onlyRole(PREDICATE_ROLE) {
        _mint(user, tokenId);
    }

    function setTokenMetadata(
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        string memory uri = abi.decode(data, (string));
        _setTokenURI(tokenId, uri);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(AccessControl, ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        super._beforeTokenTransfer(from, to, tokenId, 1);
    }

    function _setTokenURI(
        uint256 tokenId,
        string memory _tokenURI
    ) internal virtual {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI set of nonexistent token"
        );
        _tokenURIs[tokenId] = _tokenURI;
    }
}
