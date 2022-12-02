pragma solidity >=0.4.0 <0.6.0;

contract landRegistration{
    struct user {
        address userid;
        string uname;
        uint256 uaadharno;
        uint256 ucontact;
        string uemail;
        uint256 upostalCode;
        string city;
        bool exist;
    }
    struct landDetails{
        string state;
        string district;
        string city;
        uint256 surveyNumber;
        address payable CurrentOwner;
        string isGovtApproved;
        uint marketValue;
        bool isAvailable;
        address requester;
        reqStatus requestStatus;

    }
    
    enum reqStatus {Default,pending,reject,approved}
    address[] userarr;
    uint256[] assets;

    struct profiles{
        uint[] assetList;   
    }

    mapping(address => user) public users;
    mapping(uint => landDetails) land;
    address owner;
    mapping(string => address) Registrar;
    mapping(address => profiles) profile;

    function addUser(
        address uid,
        string memory _uname,
        uint256 _uaadharno,
        uint256 _ucontact,
        string memory _uemail,
        uint256 _ucode,
        string memory _ucity
    ) public returns (bool) {
        users[uid] = user(
            uid,
            _uname,
            _uaadharno,
            _ucontact,
            _uemail,
            _ucode,
            _ucity,
            true
        );
        userarr.push(uid);
        return true;
    }


    function getUser(address uid)
        public
        view
        returns (
            address,
            string memory,
            uint256,
            string memory,
            uint256,
            string memory,
            bool
        )
    {
        if (users[uid].exist)
            return (
                users[uid].userid,
                users[uid].uname,
                users[uid].ucontact,
                users[uid].uemail,
                users[uid].upostalCode,
                users[uid].city,
                users[uid].exist
            );
    }
    
    constructor() public{
        owner = msg.sender;
    }
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    function addRegistrar(address _Registrar,string memory _city ) onlyOwner public {
        Registrar[_city]=_Registrar;
    }
    function Registration(string memory _state,string memory _district,
        string memory _city,uint256 _surveyNumber,
        address payable _OwnerAddress,uint _marketValue,uint id
        ) public returns(bool) {
        require(Registrar[_city] == msg.sender && owner == msg.sender);
        land[id].state = _state;
        land[id].district = _district;
        land[id].city = _city;
        land[id].surveyNumber = _surveyNumber;
        land[id].CurrentOwner = _OwnerAddress;
        land[id].marketValue = _marketValue;
        profile[_OwnerAddress].assetList.push(id);
        assets.push(id);
        return true;
    }
    function landInfoOwner(uint id) public view returns(string memory,string memory,string memory,uint256,string memory,address,reqStatus){
        return(land[id].state,land[id].district,land[id].city,land[id].surveyNumber,land[id].isGovtApproved,land[id].requester,land[id].requestStatus);
    }
        function landInfoUser(uint id) public view returns(address,uint,bool,address,reqStatus){
        return(land[id].CurrentOwner,land[id].marketValue,land[id].isAvailable,land[id].requester,land[id].requestStatus);
    }

    function computeId(string memory _state,string memory _district,string memory _city,uint _surveyNumber) public view returns(uint){
        return uint(keccak256(abi.encodePacked(_state,_district,_city,_surveyNumber)))%10000000000000;
    }

    function requstToLandOwner(uint id) public {
        require(land[id].isAvailable);
        land[id].requester=msg.sender;
        land[id].isAvailable=false;
        land[id].requestStatus = reqStatus.pending; 
    }
    function viewAssets()public view returns(uint[] memory){
        return (profile[msg.sender].assetList);
    }

    function viewRequest(uint property)public view returns(address){
        return(land[property].requester);
    }
    function processRequest(uint property,reqStatus status)public {
        require(land[property].CurrentOwner == msg.sender);
        land[property].requestStatus=status;
        if(status == reqStatus.reject){
            land[property].requester = address(0);
            land[property].requestStatus = reqStatus.Default;
        }
    }
    function govtStatus(
        uint256 id,
        string memory status,
        bool _isAvailable
    ) public returns (bool) {
        land[id].isGovtApproved = status;
        land[id].isAvailable = _isAvailable;
        return true;
    }
    function makeAvailable(uint property)public{
        require(land[property].CurrentOwner == msg.sender);
        land[property].isAvailable=true;
    } 
    function buyProperty(uint property)public payable{
        require(land[property].requestStatus == reqStatus.approved);
        require(msg.value >= (land[property].marketValue+((land[property].marketValue)/10)));
        land[property].CurrentOwner.transfer(land[property].marketValue);
        removeOwnership(land[property].CurrentOwner,property);
        land[property].CurrentOwner=msg.sender;
        land[property].isAvailable=false;
        land[property].requester = address(0);
        land[property].requestStatus = reqStatus.Default;
        profile[msg.sender].assetList.push(property); 
    }
    
    function removeOwnership(address previousOwner,uint id)private{
        uint index = findId(id,previousOwner);
        profile[previousOwner].assetList[index]=profile[previousOwner].assetList[profile[previousOwner].assetList.length-1];
        delete profile[previousOwner].assetList[profile[previousOwner].assetList.length-1];
        profile[previousOwner].assetList.length--;
    }
    function findId(uint id,address usern)public view returns(uint){
        uint i;
        for(i=0;i<profile[usern].assetList.length;i++){
            if(profile[usern].assetList[i] == id)
                return i;
        }
        return i;
    }
}