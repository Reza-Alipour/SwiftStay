// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;


interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
    external
    view
    returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );

    function latestRoundData()
    external
    view
    returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );
}

contract PriceConverter {
    address public priceFeedAddress;

    function getPrice() public view returns (uint256, uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            priceFeedAddress
        );
        (, int256 price, , ,) = priceFeed.latestRoundData();
        uint256 decimals = priceFeed.decimals();
        return (uint256(price), decimals);
    }

    function convertFromUSD(uint256 amountInUSD) public view returns (uint256) {
        (uint256 price, uint256 decimals) = getPrice();
        uint256 convertedPrice = (amountInUSD * 10 ** decimals) / price;
        return convertedPrice;
    }
}


contract DecentralizedSwiftStay is PriceConverter {
    //--------------------------------------------------------------------
    // VARIABLES

    address public admin;

    uint256 public listingFee;
    uint256 private _rentalIds;

    struct RentalInfo {
        uint256 id;
        address owner;
        string name;
        string city;
        string latitude;
        string longitude;
        string description;
        string imgUrl;
        uint256 maxNumberOfGuests;
        uint256 pricePerDay;
    }

    struct Booking {
        address renter;
        uint256 fromTimestamp;
        uint256 toTimestamp;
    }

    RentalInfo[] public rentals;

    mapping(uint256 => Booking[]) rentalBookings;

    //--------------------------------------------------------------------
    // EVENTS

    event NewRentalCreated(
        uint256 id,
        address owner,
        string name,
        string city,
        string latitude,
        string longitude,
        string description,
        string imgUrl,
        uint256 maxGuests,
        uint256 pricePerDay,
        uint256 timestamp
    );

    event NewBookAdded(
        uint256 rentalId,
        address renter,
        uint256 bookDateStart,
        uint256 bookDateEnd,
        uint256 timestamp
    );

    //--------------------------------------------------------------------
    // ERRORS

    error DecentralSwiftStay__OnlyAdmin();
    error DecentralSwiftStay__InvalidFee();
    error DecentralSwiftStay__InvalidRentalId();
    error DecentralSwiftStay__InvalidBookingPeriod();
    error DecentralSwiftStay__AlreadyBooked();
    error DecentralSwiftStay__InsufficientAmount();
    error DecentralSwiftStay__TransferFailed();

    //--------------------------------------------------------------------
    // MODIFIERS

    modifier onlyAdmin() {
        if (msg.sender != admin) revert DecentralSwiftStay__OnlyAdmin();
        _;
    }

    modifier isRental(uint _id) {
        if (_id >= _rentalIds) revert DecentralSwiftStay__InvalidRentalId();
        _;
    }

    //--------------------------------------------------------------------
    // CONSTRUCTOR

    constructor(uint256 _listingFee, address _priceFeedAddress) {
        admin = msg.sender;
        listingFee = _listingFee;
        priceFeedAddress = _priceFeedAddress;
    }

    //--------------------------------------------------------------------
    // FUNCTIONS

    function addRental(
        string memory _name,
        string memory _city,
        string memory _latitude,
        string memory _longitude,
        string memory _description,
        string memory _imgUrl,
        uint256 _maxGuests,
        uint256 _pricePerDay
    ) external payable {
        if (msg.value != listingFee) revert DecentralSwiftStay__InvalidFee();
        uint256 _rentalId = _rentalIds;

        RentalInfo memory _rental = RentalInfo(
            _rentalId,
            msg.sender,
            _name,
            _city,
            _latitude,
            _longitude,
            _description,
            _imgUrl,
            _maxGuests,
            _pricePerDay
        );

        rentals.push(_rental);
        _rentalIds++;

        emit NewRentalCreated(
            _rentalId,
            msg.sender,
            _name,
            _city,
            _latitude,
            _longitude,
            _description,
            _imgUrl,
            _maxGuests,
            _pricePerDay,
            block.timestamp
        );
    }

    function bookDates(
        uint256 _id,
        uint256 _fromDateTimestamp,
        uint256 _toDateTimestamp
    ) external payable isRental(_id) {

        RentalInfo memory _rental = rentals[_id];

        uint256 bookingPeriod = (_toDateTimestamp - _fromDateTimestamp) /
        1 days;
        // can't book less than 1 day
        if (bookingPeriod < 1) revert DecentralSwiftStay__InvalidBookingPeriod();

        uint256 _amount = convertFromUSD(_rental.pricePerDay) * bookingPeriod;

        if (msg.value != _amount) revert DecentralSwiftStay__InsufficientAmount();
        if (checkIfBooked(_id, _fromDateTimestamp, _toDateTimestamp)) revert DecentralSwiftStay__AlreadyBooked();

        rentalBookings[_id].push(
            Booking(msg.sender, _fromDateTimestamp, _toDateTimestamp)
        );

        (bool success,) = payable(_rental.owner).call{value : msg.value}("");
        if (!success) revert DecentralSwiftStay__TransferFailed();

        emit NewBookAdded(
            _id,
            msg.sender,
            _fromDateTimestamp,
            _toDateTimestamp,
            block.timestamp
        );
    }

    function checkIfBooked(
        uint256 _id,
        uint256 _fromDateTimestamp,
        uint256 _toDateTimestamp
    ) internal view returns (bool) {

        Booking[] memory _rentalBookings = rentalBookings[_id];

        // Make sure the rental is available for the booking dates
        for (uint256 i = 0; i < _rentalBookings.length;) {
            if (
                ((_fromDateTimestamp >= _rentalBookings[i].fromTimestamp) &&
                (_fromDateTimestamp <= _rentalBookings[i].toTimestamp)) ||
                ((_toDateTimestamp >= _rentalBookings[i].fromTimestamp) &&
                (_toDateTimestamp <= _rentalBookings[i].toTimestamp))
            ) {
                return true;
            }
        unchecked {
            ++i;
        }
        }
        return false;
    }

    function getRentals() external view returns (RentalInfo[] memory) {
        return rentals;
    }

    // Return the list of booking for a given rental
    function getRentalBookings(uint256 _id)
    external
    view
    isRental(_id)
    returns (Booking[] memory)
    {
        return rentalBookings[_id];
    }

    function getRentalInfo(uint256 _id)
    external
    view
    isRental(_id)
    returns (RentalInfo memory)
    {
        return rentals[_id];
    }

    // ADMIN FUNCTIONS

    function changeListingFee(uint256 _newFee) external onlyAdmin {
        listingFee = _newFee;
    }

    function withdrawBalance() external onlyAdmin {
        (bool success,) = payable(admin).call{value : address(this).balance}("");
        if (!success) revert DecentralSwiftStay__TransferFailed();
    }
}

