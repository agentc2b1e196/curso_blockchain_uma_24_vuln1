// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract DecentralizedShipCharter {
    struct Ship {
        address owner;
        address charterer;
        uint256 price;
        bool forCharter;
    }

    mapping(uint256 => Ship) public offeredShips;
    mapping(address => uint256) public numValidCharters;
    mapping(address => uint256) public firstValidCharterTimestamp;
    mapping(address => uint256) public stakes;

    event Reimburse(address indexed charterer, uint256 amount);
    event ShipListed(uint256 indexed shipId, address indexed owner, uint256 price);
    event ShipChartered(uint256 indexed shipId, address indexed charterer, uint256 price);
    event StakeLocked(address indexed owner, uint256 amount);
    event StakeUnlocked(address indexed owner, uint256 amount);

    function listShip(uint256 shipId, uint256 price) public payable {
        require(price > 0, "Price must be greater than zero");
        require(msg.value == price, "Stake amount must be equal to charter price");

        offeredShips[shipId] = Ship(msg.sender, address(0), price, true);
        stakes[msg.sender] += msg.value;

        emit ShipListed(shipId, msg.sender, price);
        emit StakeLocked(msg.sender, msg.value);
    }

    function charterShip(uint256 shipId) public payable {
        Ship storage ship = offeredShips[shipId];
        require(ship.forCharter, "Ship not for charter");
        require(msg.value == ship.price, "Incorrect price");

        ship.charterer = msg.sender;
        ship.forCharter = false;

        emit ShipChartered(shipId, msg.sender, ship.price);
    }

    function closeCharter(uint256 shipId, bool reimburseCharterer, bool payOwner, bool releaseOwnerStake) public {
        Ship storage ship = offeredShips[shipId];
        address owner = ship.owner;
        address charterer = ship.charterer;
        uint256 price = ship.price;

        require(!ship.forCharter, "Ship is still for charter");

        // Charterer reimbursement
        if (reimburseCharterer && charterer != address(0)) {
            (bool success, ) = payable(charterer).call{value: price}("");
            require(success, "Charter reimbursement failed");
            emit Reimburse(charterer, price);
        }

        // Owner payment
        if (payOwner) {
            numValidCharters[owner]++;
            if (numValidCharters[owner] == 1) {
                firstValidCharterTimestamp[owner] = block.timestamp;
            }
            (bool success, ) = payable(owner).call{value: price}("");
            require(success, "Charter payment failed");
            uint256 stakeAmount = stakes[owner];
            stakes[owner] = 0;
            emit StakeUnlocked(owner, stakeAmount);
        }

        // Owner stake release
        if (releaseOwnerStake && !payOwner) {
            uint256 stakeAmount = stakes[owner];
            stakes[owner] = 0;
            (bool success, ) = payable(owner).call{value: stakeAmount}("");
            require(success, "Stake release failed");
            emit StakeUnlocked(owner, stakeAmount);
        }

        delete offeredShips[shipId];
    }

}
