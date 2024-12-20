// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Script, console} from "../lib/forge-std/src/Script.sol";
import {NFT} from "../src/NFT.sol";
import {NFTAuction} from "../src/NFTAuction.sol";
import {NFTMarketplace} from "../src/NFTMarketplace.sol";
import {NFTCollections} from "../src/NFTCollections.sol";
// import {PriceFeed} from "../src/PriceFeed.sol";

contract Deploy is Script {
    function run() external {
        // address priceFeedAddress = vm.envAddress("CHAINLINK_PRICE_FEED_ADDRESS");
        
        vm.startBroadcast();

        // Deploy contracts in order of dependency
        
        // 1. First deploy NFT contract with temporary addresses
        NFT nft = new NFT(
            "Krizee",
            "KRZ",
            address(1), // temporary auction address
            address(1)  // temporary marketplace address
        );

        // 2. Deploy NFTCollections (depends on NFT)
        NFTCollections collections = new NFTCollections(
            address(nft)
        );

        // 3. Deploy NFTAuction (depends on NFT and Collections)
        NFTAuction auction = new NFTAuction(
            address(nft),
            address(1) // temporary marketplace address
        );

        // 4. Deploy NFTMarketplace (depends on NFT, Collections, and Auction)
        NFTMarketplace marketplace = new NFTMarketplace(
            address(nft),
            address(collections),
            address(auction)
        );

        // // 5. Deploy PriceFeed
        // PriceFeed priceFeed = new PriceFeed(priceFeedAddress);

        // Update addresses in contracts
        nft.updateAuctionContract(address(auction));
        nft.updateMarketplaceContract(address(marketplace));
        auction.updateMarketplaceContract(address(marketplace));

        vm.stopBroadcast();

        // Log deployed addresses
        console.log("NFT deployed to:", address(nft));
        console.log("NFTCollections deployed to:", address(collections));
        console.log("NFTAuction deployed to:", address(auction));
        console.log("NFTMarketplace deployed to:", address(marketplace));
        // console.log("PriceFeed deployed to:", address(priceFeed));
    }
}
