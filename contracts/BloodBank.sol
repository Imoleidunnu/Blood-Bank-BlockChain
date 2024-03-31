// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BloodBank {
    address public admin;
    uint public totalDonors;
    uint public totalPatients;
    uint public totalHospitals;
    uint public totalBloodDonated;

    address[] public donorAddresses;
    address[] public patientAddresses;

    enum BloodType { A, B, AB, O }

    struct Donor {
        string name;
        BloodType bloodType;
        bool isRegistered;
    }

    struct Patient {
        string name;
        BloodType bloodType;
        bool isRegistered;
    }

    struct Hospital {
        string name;
        address location;
        bool isRegistered;
    }

    struct Request {
        bool isResponded;
        BloodType bloodType;
        uint amount;
        bool response;
    }

    mapping(address => Donor) public donors;
    mapping(address => Patient) public patients;
    mapping(address => Hospital) public hospitals;
    mapping(address => bool) public allowedDonors;
    mapping(address => bool) public allowedPatients;
    mapping(address => mapping(BloodType => uint)) public donorBalances;
    mapping(address => mapping(BloodType => Request[])) public patientRequests;
    mapping(address => Request[]) public patientResponses; // Add mapping to store responses

    event AdminLoggedIn(address admin);
    event DonorRegistered(address donor, string name, BloodType bloodType);
    event PatientRegistered(address patient, string name, BloodType bloodType);
    event HospitalRegistered(address hospital, string name, address location);
    event BloodDonated(address donor, BloodType bloodType, uint amount);
    event BloodRequested(address patient, BloodType bloodType);
    event DonorPermissionGranted(address donor);
    event DonorPermissionRevoked(address donor);
    event PatientPermissionGranted(address patient);
    event PatientPermissionRevoked(address patient);
    event RequestResponded(address patient, bool response, BloodType bloodType, uint amount);

    modifier isAdmin() {
        require(msg.sender == admin, "Only the admin can perform this action");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    function adminLogin() public returns (bool) {
        require(admin == address(0), "Admin already logged in");
        admin = msg.sender;
        emit AdminLoggedIn(admin);
        return true;
    }

    function grantDonorPermission(address donorAddress) public isAdmin {
        require(!allowedDonors[donorAddress], "Donor already has permission");
        allowedDonors[donorAddress] = true;
        emit DonorPermissionGranted(donorAddress);
    }

    function revokeDonorPermission(address donorAddress) public isAdmin {
        require(allowedDonors[donorAddress], "Donor does not have permission");
        allowedDonors[donorAddress] = false;
        emit DonorPermissionRevoked(donorAddress);
    }

    function grantPatientPermission(address patientAddress) public isAdmin {
        require(!allowedPatients[patientAddress], "Patient already has permission");
        allowedPatients[patientAddress] = true;
        emit PatientPermissionGranted(patientAddress);
    }

    function revokePatientPermission(address patientAddress) public isAdmin {
        require(allowedPatients[patientAddress], "Patient does not have permission");
        allowedPatients[patientAddress] = false;
        emit PatientPermissionRevoked(patientAddress);
    }

    function addPatient(address patientAddress, string memory name, BloodType bloodType) public isAdmin {
        require(!patients[patientAddress].isRegistered, "Patient already registered");
        patients[patientAddress] = Patient(name, bloodType, true);
        patientAddresses.push(patientAddress);
        totalPatients++;
        emit PatientRegistered(patientAddress, name, bloodType);
    }

    function addHospital(address hospitalAddress, string memory name, address location) public isAdmin {
        require(!hospitals[hospitalAddress].isRegistered, "Hospital already registered");
        hospitals[hospitalAddress] = Hospital(name, location, true);
        totalHospitals++;
        emit HospitalRegistered(hospitalAddress, name, location);
    }

    function registerAsDonor(string memory name, BloodType bloodType) public {
        require(!donors[msg.sender].isRegistered, "Donor already registered");
        donors[msg.sender] = Donor(name, bloodType, true);
        donorAddresses.push(msg.sender);
        totalDonors++;
        emit DonorRegistered(msg.sender, name, bloodType);
    }

    function donateBlood(BloodType bloodType, uint amount) public {
        require(donors[msg.sender].isRegistered, "Donor not registered");
        donorBalances[msg.sender][bloodType] += amount;
        totalBloodDonated += amount;
        emit BloodDonated(msg.sender, bloodType, amount);
    }

    function requestBlood(BloodType bloodType, uint amount) public {
        require(patients[msg.sender].isRegistered, "You need to register as a patient first");
        Request memory newRequest = Request({
            isResponded: false,
            bloodType: bloodType,
            amount: amount,
            response: false
        });
        patientRequests[msg.sender][bloodType].push(newRequest);
        emit BloodRequested(msg.sender, bloodType);
    }

    function respondToRequest(address patientAddress, BloodType bloodType, bool response) public isAdmin {
        require(patientRequests[patientAddress][bloodType].length > 0, "No blood donation request found");
        Request storage lastRequest = patientRequests[patientAddress][bloodType][patientRequests[patientAddress][bloodType].length - 1];
        lastRequest.isResponded = true;
        lastRequest.response = response;
        patientResponses[patientAddress].push(lastRequest);
        emit RequestResponded(patientAddress, response, lastRequest.bloodType, lastRequest.amount);
    }

    function getPatientResponses(address patientAddress) public view returns (Request[] memory) {
        return patientResponses[patientAddress];
    }

    function getRegisteredUsers() public view returns (address[] memory registeredDonors, address[] memory registeredPatients) {
        return (donorAddresses, patientAddresses);
    }
}

