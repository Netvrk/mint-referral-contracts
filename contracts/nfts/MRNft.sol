// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

contract MrNft is ERC2981, ERC721Enumerable, AccessControl {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER");

    string internal _baseTokenURI;
    string private _contractURI;
    mapping(uint256 => string) private _tokenURIs;
    mapping(string => uint256) private _axeIdToTokenId;
    mapping(uint256 => string) private _tokenIdToAxeId;

    constructor(
        string memory baseTokenURI,
        address manager_
    ) ERC721("MrNft", "MrNft") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MANAGER_ROLE, manager_);

        _baseTokenURI = baseTokenURI;
        _tokenIds.increment();
    }

    /**
    ////////////////////////////////////////////////////
    // Public functions
    ///////////////////////////////////////////////////
    */

    // Mint game item
    function mintItem(
        address player,
        string memory axeId,
        string memory axeType
    ) public onlyRole(MANAGER_ROLE) {
        require(_axeIdToTokenId[axeId] == 0, "AXE_ALREADY_MINTED");

        uint256 itemId = _tokenIds.current();

        string memory itemURI = string.concat(
            Strings.toString(itemId),
            "/",
            axeType
        );

        _mint(player, itemId);

        _axeIdToTokenId[axeId] = itemId;
        _tokenIdToAxeId[itemId] = axeId;

        _setTokenURI(itemId, itemURI);

        _tokenIds.increment();
    }

    // Burn game item
    function burnItem(
        uint256 itemId
    ) public onlyRole(DEFAULT_ADMIN_ROLE) returns (uint256) {
        _burn(itemId);
        return itemId;
    }

    // Set base URI
    function setBaseURI(
        string memory baseTokenURI
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _baseTokenURI = baseTokenURI;
    }

    // Set default royalty
    function setDefaultRoyalty(
        address receiver,
        uint96 royalty
    ) external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _setDefaultRoyalty(receiver, royalty);
    }

    // Set Contract URI
    function setContractURI(
        string memory newContractURI
    ) external virtual onlyRole(MANAGER_ROLE) {
        _contractURI = newContractURI;
    }

    /**
    ////////////////////////////////////////////////////
    // View only functions
    ///////////////////////////////////////////////////
    */

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    // Get contract URI
    function contractURI() external view virtual returns (string memory) {
        return _contractURI;
    }

    // Get token ID from axe ID
    function axeIdToTokenId(
        string memory axeId
    ) external view returns (uint256) {
        return _axeIdToTokenId[axeId];
    }

    // Get axe ID from token ID
    function tokenIdToAxeId(
        uint256 tokenId
    ) external view returns (string memory) {
        return _tokenIdToAxeId[tokenId];
    }

    /**
    ////////////////////////////////////////////////////
    // Internal functions
    ///////////////////////////////////////////////////
    */

    function _setTokenURI(
        uint256 tokenId,
        string memory _tokenURI
    ) internal virtual {
        require(_exists(tokenId), "TOKEN_DOESNT_EXIST");
        _tokenURIs[tokenId] = _tokenURI;
    }

    // Get base URI
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC2981, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        if (interfaceId == type(IERC2981).interfaceId) {
            return true;
        }

        return super.supportsInterface(interfaceId);
    }
}
