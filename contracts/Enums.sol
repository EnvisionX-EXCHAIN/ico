pragma solidity ^0.4.20;

contract Enums {
    // Type for mapping uint (index) => name for baskets types described in WP
    enum BasketType {
        unknown, // 0 unknown
        team, // 1 Team
        foundation, // 2 Foundation
        arr, // 3 Advertisement, Referral program, Reward
        advisors, // 4 Advisors
        bounty, // 5 Bounty
        referral, // 6 Referral
        referrer // 7 Referrer
    }
}
