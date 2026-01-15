// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ERC721} from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

contract VoteNFT is ERC721, Ownable {
    uint256 private _nextTokenId;

    // Le constructeur prend l'adresse du propriétaire (qui sera le VotingSystem)
    constructor(address initialOwner) ERC721("Voter Pass", "VPASS") Ownable(initialOwner) {}

    function mint(address to) public onlyOwner {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
    }
}