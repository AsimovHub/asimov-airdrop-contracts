// SPDX-License-Identifier: UNLICENSED
// Code written by n-three for Asimov Hub

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract TokenDistributor is Ownable {
    using SafeMath for uint256;

    address _tokenContract;
    address _nftContract;

    uint256 _minHoldingAmount;

    uint256 _distributedCount;
    uint256 _filterCount;

    uint256 _lastCheckedDistributionIndex;


    address[] _finalQualifiedParticipants;

    constructor(address owner_, address tokenContract_, address nftContract_) {
        _tokenContract = tokenContract_;
        _nftContract = nftContract_;
        _transferOwnership(owner_);
    }

    function isAirdropCompleted() public view returns (bool) {
        if (_finalQualifiedParticipants.length == 0) {
            return _distributedCount >= getTotalSupply();
        } else {
            return _distributedCount >= _finalQualifiedParticipants.length;
        }
    }

    function isClosed() public view returns (bool) {
        return _filterCount >= getTotalSupply();
    }

    function finalize() external onlyOwner {
        uint256 totalSupply = getTotalSupply();

        if (_minHoldingAmount > 0) {
            uint256 c = 0;
            for (uint256 i = _filterCount; c < 250 && i < totalSupply; i++) {
                address currentHolder = IERC721(_nftContract).ownerOf(i);
                if (IERC20(_tokenContract).balanceOf(currentHolder) >= _minHoldingAmount) {
                    _finalQualifiedParticipants.push(currentHolder);
                }
                _filterCount++;
                c++;
            }
        } else {
            _filterCount = totalSupply;
        }
    }

    function revertFinalize() external onlyOwner {
        require(isClosed(), "Airdrop has not been finalized");
        require(!isAirdropCompleted(), "Airdrop has been finished");
        _filterCount = 0;
        delete _finalQualifiedParticipants;
    }

    function distribute() external onlyOwner {
        require(isClosed(), "Airdrop has not been finalized");
        require(!isAirdropCompleted(), "Airdrop has been finished");

        uint256 totalSupply = getTotalSupply();

        uint256 leftTokens = IERC20(_tokenContract).balanceOf(address(this));
        require(leftTokens > 0, "No tokens available");

        uint256 totalParticipants = _finalQualifiedParticipants.length == 0 ? totalSupply : _finalQualifiedParticipants.length;

        uint256 payoutAmount = leftTokens / (totalParticipants - _distributedCount);
        uint256 c = 0;
        for (uint256 i = _lastCheckedDistributionIndex; c < 250 && i < totalParticipants; i++) {
            address currentHolder = _finalQualifiedParticipants.length == 0 ? IERC721(_nftContract).ownerOf(i) : _finalQualifiedParticipants[i];
            if (IERC20(_tokenContract).balanceOf(currentHolder) >= _minHoldingAmount) {
                IERC20(_tokenContract).transfer(currentHolder, payoutAmount);
                _distributedCount++;
            }
            _lastCheckedDistributionIndex++;
            c++;
        }
    }

    function getQualifiedParticipants() public view returns (address[] memory) {
        require(isClosed(), "Airdrop not finalized yet");
        return _finalQualifiedParticipants;
    }

    function getQualifiedTotalSupply() public view returns (uint256) {
        require(isClosed(), "Airdrop not finalized yet");
        return _finalQualifiedParticipants.length == 0 ? getTotalSupply() : _finalQualifiedParticipants.length;
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

    function getFilterCount() external view returns (uint256) {
        return _filterCount;
    }

    function getLastCheckedIndex() external view returns (uint256) {
        return _lastCheckedDistributionIndex;
    }

    function getTotalSupply() public view returns (uint256) {
        return IERC721Enumerable(_nftContract).totalSupply();
    }

    function setMinHoldingAmount(uint256 minHoldingAmount_) external onlyOwner {
        require(!isClosed(), "Airdrop has been already finalized");
        _minHoldingAmount = minHoldingAmount_;
    }

    function withdraw() external onlyOwner {
        uint256 currentBalance = IERC20(_tokenContract).balanceOf(address(this));
        require(currentBalance > 0, "The contract does not hold any funds");
        IERC20(_tokenContract).transfer(msg.sender, currentBalance);
    }
}
