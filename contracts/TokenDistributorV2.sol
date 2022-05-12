// SPDX-License-Identifier: UNLICENSED
// Code written by n-three for Asimov Hub

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract TokenDistributorV2 is Ownable {
    using SafeMath for uint256;

    address _tokenContract;
    address _nftContract;

    uint256 _minHoldingAmount;

    uint256 _distributedCount;
    uint256 _lastCheckedIndex;

    address[] _finalizedQualifiedParticipants;

    constructor(address owner_, address tokenContract_, address nftContract_) {
        _tokenContract = tokenContract_;
        _nftContract = nftContract_;
        _minHoldingAmount = 0;

        _distributedCount = 0;
        _lastCheckedIndex = 0;

        _transferOwnership(owner_);
    }

    function isAirdropCompleted() external view returns (bool) {
        return _lastCheckedIndex >= getTotalSupply() - 1;
    }

    function isClosed() external view returns (bool) {
        return _finalizedQualifiedParticipants.length > 0;
    }

    function finalize() external onlyOwner {
        require(getQualifiedTotalSupply() > 0, "No one is qualified");
        uint256 totalSupply = getTotalSupply();
        for (uint256 i = 0; i < totalSupply; i++) {
            address a = IERC721(_nftContract).ownerOf(i);
            if (IERC20(_tokenContract).balanceOf(a) >= _minHoldingAmount) {
                _finalizedQualifiedParticipants.push(a);
            }
        }
    }

    function distribute() external onlyOwner {
        require(_finalizedQualifiedParticipants.length > 0, "Airdrop has not been finalized");
        require(_lastCheckedIndex < getTotalSupply(), "Airdrop has been finished");

        uint256 leftTokens = IERC20(_tokenContract).balanceOf(address(this));
        require(leftTokens > 0, "No tokens available");

        uint256 payoutAmount = leftTokens / (_finalizedQualifiedParticipants.length - _distributedCount);

        for (uint256 i = _distributedCount; i < _finalizedQualifiedParticipants.length && i < _distributedCount + 250; i++) {
            IERC20(_tokenContract).transfer(_finalizedQualifiedParticipants[i], payoutAmount);
            _distributedCount++;
            _lastCheckedIndex++;
        }
    }

    function getQualifiedParticipants() public view returns (address[] memory) {
        return _finalizedQualifiedParticipants;
    }

    function getQualifiedTotalSupply() public view returns (uint256) {
        if (_finalizedQualifiedParticipants.length > 0) {
            return _finalizedQualifiedParticipants.length;
        }
        if (_minHoldingAmount == 0) {
            return getTotalSupply();
        } else {
            // COUNT
            uint256 count = 0;
            for (uint256 i = 0; i < getTotalSupply(); i++) {
                if (IERC20(_tokenContract).balanceOf(IERC721(_nftContract).ownerOf(i)) >= _minHoldingAmount) {
                    count++;
                }
            }
            return count;
        }
    }

    function getTokenContract() external view returns (address) {
        return _tokenContract;
    }

    function getNFTContract() external view returns (address) {
        return _nftContract;
    }

    function getMinHoldingAmount() external view returns (uint256) {
        return _minHoldingAmount;
    }

    function getDistributedCount() external view returns (uint256) {
        return _distributedCount;
    }

    function getLastCheckedIndex() external view returns (uint256) {
        return _lastCheckedIndex;
    }

    function getTotalSupply() public view returns (uint256) {
        return IERC721Enumerable(_nftContract).totalSupply();
    }

    function setMinHoldingAmount(uint256 minHoldingAmount_) external onlyOwner {
        _minHoldingAmount = minHoldingAmount_;
    }

    function withdraw() external onlyOwner {
        uint256 currentBalance = IERC20(_tokenContract).balanceOf(address(this));
        require(currentBalance > 0, "The contract does not hold any funds");
        IERC20(_tokenContract).transfer(msg.sender, currentBalance);
    }
}
