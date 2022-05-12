// SPDX-License-Identifier: UNLICENSED
// Code written by n-three for Asimov Hub

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./TokenDistributor.sol";

contract DistributorDeployer is Ownable {
    using SafeMath for uint256;

    address constant ISAAC_TOKEN_CONTRACT = 0x86FF8138dcA8904089D3d003d16a5a2d710D36D2;

    address internal _discountContract;
    address internal _paymentAddress;
    uint256 internal _distributionFee;
    uint256 internal _discountRate;

    // map caller to its current airdrop contract
    mapping (address => address) _activeAirdrops;

    constructor() {
        _discountContract = 0x046582b91d68cc5FDF02A045920c017140A8E503;
        _paymentAddress = 0x000000000000000000000000000000000000dEaD;
        _distributionFee = 50000 * 10 ** 18;
        _discountRate = 100;
    }

    function createAirdrop(address tokenContract_, address nftContract_) external {
        uint256 price = getPriceForUser(msg.sender);

        if (price > 0) {
            transferISAACPayment(price);
        }

        TokenDistributor token = new TokenDistributor(msg.sender, tokenContract_, nftContract_);
        _activeAirdrops[msg.sender] = address(token);
    }

    function getAirdropByOwner(address owner_) external view returns (address) {
        return _activeAirdrops[owner_];
    }

    function getPriceForUser(address user_) public view returns (uint256) {
        if (hasDiscount(user_)) {
            return _distributionFee / 100 * (100 - _discountRate);
        } else {
            return _distributionFee;
        }
    }

    function hasDiscount(address holder) public view returns (bool) {
        if (_discountContract != address(0) && _discountRate != 0) {
            return IERC721(_discountContract).balanceOf(holder) > 0;
        } else {
            return false;
        }
    }

    function transferISAACPayment(uint256 amount) internal {
        require(IERC20(ISAAC_TOKEN_CONTRACT).balanceOf(msg.sender) >= amount, "You do not hold enough ISAAC");
        require(IERC20(ISAAC_TOKEN_CONTRACT).allowance(msg.sender, address(this)) >= amount, "You must allow payment first");
        require(IERC20(ISAAC_TOKEN_CONTRACT).transferFrom(msg.sender, address(this), amount), "Error during transfer");
        require(IERC20(ISAAC_TOKEN_CONTRACT).transfer(_paymentAddress, amount), "Error during transfer");
    }

    function getDiscountContract() external view returns (address) {
        return _discountContract;
    }

    function getPaymentAddress() external view returns (address) {
        return _discountContract;
    }

    function getDistributionFee() external view returns (uint256) {
        return _distributionFee;
    }

    function getDiscountRate() external view returns (uint256) {
        return _discountRate;
    }

    function setDiscountContract(address contract_) external onlyOwner {
        _discountContract = contract_;
    }

    function setPaymentAddress(address contract_) external onlyOwner {
        _paymentAddress = contract_;
    }

    function setDistributionFee(uint256 fee_) external onlyOwner {
        _distributionFee = fee_;
    }

    function setDiscountRate(uint256 rate_) external onlyOwner {
        _discountRate = rate_;
    }
}
