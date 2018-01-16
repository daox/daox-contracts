interface TokenInterface {
    function mint(address _to, uint256 _amount) public returns (bool);
    function finishMinting() public returns (bool);
    function totalSupply() public constant returns (uint);
    function balanceOf(address _address) public constant returns (uint);
    function burn(address burner);
    function hold(address addr, uint duration) external;
}

interface VotingFactoryInterface {
    function createProposal(address _creator, bytes32 _description, uint _duration, bytes32[] _options) external returns (address);

    function createWithdrawal(address _creator, bytes32 _description, uint _duration, uint _sum, uint quorum, address withdrawalWallet) external returns (address);

    function createRefund(address _creator, bytes32 _description, uint _duration, uint quorum) external returns (address);

    function createWhiteList(address _creator, bytes32 _description, uint _duration, uint quorum, address _addr, uint action) external returns (address);

    function setDaoFactory(address _dao) external;
}

library DAOLib {
    event VotingCreated(address voting, string votingType, address dao, bytes32 description, uint duration, address sender);

    function countTokens(uint weiAmount, uint[] bonusPeriods, uint[] bonusRates, uint rate) returns(uint) {
        for(uint i = 0; i < bonusPeriods.length; i++) {
            if (now < bonusPeriods[i]) {
                rate = bonusRates[i];
                break;
            }
        }
        uint tokensAmount = weiAmount * rate;

        return tokensAmount;
    }

    function countRefundSum(uint tokenAmount, uint rate, uint newRate) constant returns (uint) {
        uint multiplier = 1000;
        uint newRateToOld = newRate*multiplier / rate;
        uint weiSpent = tokenAmount / rate;
        return weiSpent*multiplier / newRateToOld;
    }

    function handleFinishedCrowdsale(TokenInterface token, uint commissionRaised, address serviceContract, uint[] teamBonuses, address[] team, uint[] teamHold) {
        uint commission = (commissionRaised/100)*4;
        serviceContract.call.gas(200000).value(commission)();
        uint totalSupply = token.totalSupply() / 100;
        for(uint i = 0; i < team.length; i++) {
            token.mint(team[i], (totalSupply*teamBonuses[i]));
            token.hold(team[i], teamHold[i]);
        }
    }

    function delegateRemove(address _parentAddress, address _participantAddress) {
        require(_parentAddress.delegatecall(bytes4(keccak256("remove(address)")), _participantAddress));
    }

    //ToDo: finish proposal creating functions
    function delegatedCreateProposal(address _votingFactory, bytes32 _description, uint _duration, bytes32[] _options, address _dao) returns (address) {
        address _votingAddress = VotingFactoryInterface(_votingFactory).createProposal(msg.sender, _description, _duration, _options);
        VotingCreated(_votingAddress, "proposal", _dao, _description, _duration, msg.sender);
        return _votingAddress;
    }

    function delegatedCreateWithdrawal(address _votingFactory, bytes32 _description, uint _duration, uint _sum, address withdrawalWallet, address _dao) returns (address) {
        address _votingAddress = VotingFactoryInterface(_votingFactory).createWithdrawal(msg.sender, _description, _duration, _sum, 51, withdrawalWallet);
        VotingCreated(_votingAddress, "withdrawal", _dao, _description, _duration, msg.sender);
        return _votingAddress;
    }

    function delegatedCreateRefund(address _votingFactory, bytes32 _description, uint _duration, address _dao) returns (address) {
        address _votingAddress = VotingFactoryInterface(_votingFactory).createRefund(msg.sender, _description, _duration, 51);
        VotingCreated(_votingAddress, "refund", _dao, _description, _duration, msg.sender);
        return _votingAddress;
    }

    function delegatedCreateWhiteList(address _votingFactory, bytes32 _description, uint _duration, address _addr, uint action, address _dao) returns (address) {
        address _votingAddress = VotingFactoryInterface(_votingFactory).createWhiteList(msg.sender, _description, _duration, 51, _addr, action);
        VotingCreated(_votingAddress, "whiteList", _dao, _description, _duration, msg.sender);
        return _votingAddress;
    }

    function delegatedInitCrowdsaleParameters(address _p, uint softCap, uint hardCap, uint rate, uint startTime, uint endTime) {
        require(_p.delegatecall(bytes4(keccak256("initCrowdsaleParameters(uint256,uint256,uint256,uint256,uint256)")), softCap, hardCap, rate, startTime, endTime));
    }

    function delegatedCreate(address _p, address _usersAddress, uint8 _minVote, address _tokenAddress,
        address _votingFactory, address _serviceContract, address _parentAddress) {
        require(_p.delegatecall(bytes4(keccak256("create(address,uint8,address,address,address,address)")),
            _usersAddress, _minVote, _tokenAddress, _votingFactory, _serviceContract, _parentAddress));
    }

    function delegatedHandlePayment(address _p, address sender, bool commission) {
        require(_p.delegatecall(bytes4(keccak256("handlePayment(address,bool)")), sender, commission));
    }

    function delegatedFinish(address _p) {
        require(_p.delegatecall(bytes4(keccak256("finish()"))));
    }
}

contract CrowdsaleDAOFields {
    uint public rate;
    uint public softCap;
    uint public hardCap;
    uint public startTime;
    uint public endTime;
    bool public canInitCrowdsaleParameters = true;
    bool public canInitStateParameters = true;
    bool public canInitBonuses = true;
    bool public canSetWhiteList = true;
    uint public commissionRaised = 0;
    uint public weiRaised = 0;
    mapping(address => uint) public depositedWei;
    mapping(address => uint) public depositedWithCommission;
    bool public crowdsaleFinished;
    bool public refundableSoftCap = false;
    uint newRate = 0;
    address public serviceContract;
    uint[] public teamBonusesArr;
    address[] public team;
    uint[] public teamHold;
    TokenInterface public token;
    VotingFactoryInterface public votingFactory;
    address public commissionContract;
    string public name;
    uint public created_at = now; // UNIX time
    bytes32 public description;
    uint public minVote; // in percents
    mapping(address => bool) public votings;
    bool public refundable = false;
    uint internal lastWithdrawalTimestamp = 0;
    uint constant internal withdrawalPeriod = 120 * 24 * 60 * 60;
    address[] public whiteListArr;
    mapping(address => bool) public whiteList;
    mapping(address => uint) public teamBonuses;
    uint[] public bonusPeriods;
    uint[] public bonusRates;
}

contract Owned {
    address owner;

    function Owned(address _owner) {
        owner = _owner;
    }

    modifier onlyOwner(address _sender) {
        require(_sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner(msg.sender) {
        owner = newOwner;
    }
}
interface IDAOPayable {
    function handleCommissionPayment(address _sender) payable;
}

contract Commission {
    IDAOPayable dao;

    function Commission(address _dao) {
        dao = IDAOPayable(_dao);
    }

    function() payable {
        dao.handleCommissionPayment.value(msg.value)(msg.sender);
    }
}

contract State is CrowdsaleDAOFields {
    address public owner;

    event State(address _comission);

    function initState(uint _minVote, address _tokenAddress, address _votingFactory, address _serviceContract) external onlyOwner(msg.sender) canInit {
        require(_tokenAddress != 0x0 && _votingFactory != 0x0 && _serviceContract != 0x0);

        token = TokenInterface(_tokenAddress);
        votingFactory = VotingFactoryInterface(_votingFactory);
        minVote = _minVote;
        created_at = block.timestamp;

        serviceContract = _serviceContract;
        commissionContract = new Commission(this);

        canInitStateParameters = false;

        State(commissionContract);
    }

    modifier canInit() {
        require(canInitStateParameters);
        _;
    }

    modifier crowdsaleNotStarted() {
        require(startTime == 0 || block.timestamp < startTime);
        _;
    }

    modifier onlyOwner(address _sender) {
        require(_sender == owner);
        _;
    }
}

contract Crowdsale is CrowdsaleDAOFields {
    address public owner;

    function initCrowdsaleParameters(uint _softCap, uint _hardCap, uint _rate, uint _startTime, uint _endTime) onlyOwner(msg.sender) canInit {
        require(_softCap != 0 && _hardCap != 0 && _rate != 0 && _startTime != 0 && _endTime != 0);
        require(_softCap < _hardCap && _startTime > block.timestamp);
        softCap = _softCap * 1 ether;
        hardCap = _hardCap * 1 ether;

        startTime = _startTime;
        endTime = _endTime;

        rate = _rate;

        canInitCrowdsaleParameters = false;
    }

    function finish() {
        require(block.timestamp >= endTime && !crowdsaleFinished);

        crowdsaleFinished = true;

        if(weiRaised >= softCap) DAOLib.handleFinishedCrowdsale(token, commissionRaised, serviceContract, teamBonusesArr, team, teamHold);
        else {
            refundableSoftCap = true;
            newRate = rate;
        }

        token.finishMinting();
    }

    function handlePayment(address _sender, bool commission) payable CrowdsaleStarted validPurchase(msg.value) external {
        require(_sender != 0x0);

        uint weiAmount = msg.value;
        if(commission) {
            commissionRaised = commissionRaised + weiAmount;
            depositedWithCommission[_sender] += weiAmount;
        }

        weiRaised += weiAmount;
        depositedWei[_sender] += weiAmount;

        uint tokensAmount = DAOLib.countTokens(weiAmount, bonusPeriods, bonusRates, rate);
        token.mint(_sender, tokensAmount);
    }

    modifier canInit() {
        require(canInitCrowdsaleParameters);
        _;
    }

    modifier onlyCommission() {
        require(commissionContract == msg.sender);
        _;
    }

    modifier CrowdsaleStarted() {
        require(block.timestamp >= startTime);
        _;
    }

    modifier validPurchase(uint value) {
        require(weiRaised + value < hardCap && block.timestamp < endTime);
        _;
    }

    modifier onlyOwner(address _sender) {
        require(_sender == owner);
        _;
    }
}

contract Payment is CrowdsaleDAOFields {
    function getCommissionTokens() onlyParticipant succeededCrowdsale {
        require(depositedWithCommission[msg.sender] > 0);
        uint depositedWithCommissionAmount = depositedWithCommission[msg.sender];
        delete depositedWithCommission[msg.sender];
        assert(serviceContract.call(bytes4(keccak256("getCommissionTokens(address,uint256)")), msg.sender, depositedWithCommissionAmount));
    }

    function refund() whenRefundable {
        require(teamBonuses[msg.sender] == 0);

        uint tokensAmount = token.balanceOf(msg.sender);
        token.burn(msg.sender);
        msg.sender.transfer(DAOLib.countRefundSum(tokensAmount, rate, newRate)*1 wei);
    }

    function refundSoftCap() whenRefundableSoftCap {
        require(depositedWei[msg.sender] != 0);

        token.burn(msg.sender);
        uint weiAmount = depositedWei[msg.sender];
        delete depositedWei[msg.sender];
        msg.sender.transfer(weiAmount);
    }

    modifier whenRefundable() {
        require(refundable);
        _;
    }

    modifier whenRefundableSoftCap() {
        require(refundableSoftCap);
        _;
    }

    modifier onlyParticipant {
        require(token.balanceOf(msg.sender) > 0);
        _;
    }

    modifier succeededCrowdsale() {
        require(crowdsaleFinished && weiRaised >= softCap);
        _;
    }
}
contract VotingDecisions is CrowdsaleDAOFields {

    function withdrawal(address _address, uint withdrawalSum) onlyVoting external {
        assert(_address.call.value(withdrawalSum * 1 ether)());
        lastWithdrawalTimestamp = block.timestamp;
    }

    function makeRefundableByUser() external {
        require(lastWithdrawalTimestamp != 0 && block.timestamp >= lastWithdrawalTimestamp + withdrawalPeriod);
        makeRefundable();
    }

    function makeRefundableByVotingDecision() external onlyVoting {
        makeRefundable();
    }

    function makeRefundable() private {
        require(!refundable);
        refundable = true;
        newRate = token.totalSupply() / this.balance;
    }

    function holdTokens(address _address, uint duration) onlyVoting external {
        token.hold(_address, duration);
    }

    function flushWhiteList() onlyVoting external {
        for(uint i = 0; i < whiteListArr.length; i++) {
            delete whiteList[whiteListArr[i]];
        }
    }

    function changeWhiteList(address _addr, bool res) onlyVoting external {
        if (res) {
            whiteList[_addr] = true;
            whiteListArr.push(_addr);

            return;
        }

        delete whiteList[_addr];

        address[] memory whiteListArrCopy = whiteListArr;
        whiteListArr = new address[](0);

        for (uint i = 0; i < whiteListArrCopy.length; i++) {
            if (whiteListArrCopy[i] != _addr) whiteListArr.push(whiteListArrCopy[i]);
        }
    }

    modifier onlyVoting() {
        require(votings[msg.sender]);
        _;
    }
}
interface DAOFactoryInterface {
    function exists(address _address) constant returns (bool);
}

library DAODeployer {
    function deployCrowdsaleDAO(string _name,  bytes32 _description) returns(CrowdsaleDAO dao) {
        dao = new CrowdsaleDAO(_name, _description);
    }

    function transferOwnership(address _dao, address _newOwner) {
        CrowdsaleDAO(_dao).transferOwnership(_newOwner);
    }
}

library DAOProxy {
    function delegatedInitState(address stateModule, uint _minVote, address _tokenAddress, address _votingFactory, address _serviceContract) {
        require(stateModule.delegatecall(bytes4(keccak256("initState(uint256,address,address,address)")), _minVote, _tokenAddress, _votingFactory, _serviceContract));
    }

    function delegatedHoldState(address stateModule, uint _tokenHoldTime) {
        require(stateModule.delegatecall(bytes4(keccak256("initHold(uint256)")), _tokenHoldTime));
    }

    function delegatedGetCommissionTokens(address paymentModule) {
        require(paymentModule.delegatecall(bytes4(keccak256("getCommissionTokens()"))));
    }

    function delegatedRefund(address paymentModule) {
        require(paymentModule.delegatecall(bytes4(keccak256("refund()"))));
    }

    function delegatedRefundSoftCap(address paymentModule) {
        require(paymentModule.delegatecall(bytes4(keccak256("refundSoftCap()"))));
    }

    function delegatedWithdrawal(address votingDecisionModule, address _address, uint withdrawalSum) {
        require(votingDecisionModule.delegatecall(bytes4(keccak256("withdrawal(address,uint256)")), _address, withdrawalSum));
    }

    function delegatedMakeRefundableByUser(address votingDecisionModule) {
        require(votingDecisionModule.delegatecall(bytes4(keccak256("makeRefundableByUser()"))));
    }

    function delegatedMakeRefundableByVotingDecision(address votingDecisionModule) {
        require(votingDecisionModule.delegatecall(bytes4(keccak256("makeRefundableByVotingDecision()"))));
    }

    function delegatedHoldTokens(address votingDecisionModule, address _address, uint duration) {
        require(votingDecisionModule.delegatecall(bytes4(keccak256("holdTokens(address,uint256)")), _address, duration));
    }

    function delegatedFlushWhiteList(address votingDecisionModule) {
        require(votingDecisionModule.delegatecall(bytes4(keccak256("flushWhiteList()"))));
    }

    function delegatedChangeWhiteList(address votingDecisionModule, address _addr, bool res) {
        require(votingDecisionModule.delegatecall(bytes4(keccak256("changeWhiteList(address,bool)")), _addr, res));
    }

    function delegatedInitCrowdsaleParameters(address crowdsaleModule, uint _softCap, uint _hardCap, uint _rate, uint _startTime, uint _endTime) {
        require(crowdsaleModule.delegatecall(bytes4(keccak256("initCrowdsaleParameters(uint256,uint256,uint256,uint256,uint256)")), _softCap, _hardCap, _rate, _startTime, _endTime));
    }

    function delegatedFinish(address crowdsaleModule) {
        require(crowdsaleModule.delegatecall(bytes4(keccak256("finish()"))));
    }

    function delegatedHandlePayment(address crowdsaleModule, address _sender, bool _commission) {
        require(crowdsaleModule.delegatecall(bytes4(keccak256("handlePayment(address,bool)")), _sender, _commission));
    }
}

library Common {
    function stringToBytes32(string memory source) returns (bytes32 result) {
        assembly {
            result := mload(add(source, 32))
        }
    }

    function percent(uint numerator, uint denominator, uint precision) constant returns(uint quotient) {
        uint _numerator  = numerator * 10 ** (precision+1);
        uint _quotient =  ((_numerator / denominator) + 5) / 10;
        return ( _quotient);
    }

}

contract CrowdsaleDAO is CrowdsaleDAOFields, Owned {
    address public stateModule;
    address public paymentModule;
    address public votingDecisionModule;
    address public crowdsaleModule;

    function CrowdsaleDAO(string _name, bytes32 _description)
    Owned(msg.sender)
    {
        (name, description) = (_name, _description);
    }

    /*
        State module related functions
    */
    function initState(uint _minVote, address _tokenAddress, address _votingFactory, address _serviceContract) external {
        DAOProxy.delegatedInitState(stateModule, _minVote, _tokenAddress, _votingFactory, _serviceContract);
    }

    function initHold(uint _tokenHoldTime) external {
        DAOProxy.delegatedHoldState(stateModule, _tokenHoldTime);
    }

    /*
        Crowdsale module related functions
    */
    function initCrowdsaleParameters(uint _softCap, uint _hardCap, uint _rate, uint _startTime, uint _endTime) external {
        DAOProxy.delegatedInitCrowdsaleParameters(crowdsaleModule, _softCap, _hardCap, _rate, _startTime, _endTime);
    }

    function() payable {
        DAOProxy.delegatedHandlePayment(crowdsaleModule, msg.sender, false);
    }

    function handleCommissionPayment(address _sender) payable {
        DAOProxy.delegatedHandlePayment(crowdsaleModule, _sender, true);
    }

    function finish() {
        DAOProxy.delegatedFinish(crowdsaleModule);
    }

    /*
        Voting module related functions
    */
    function flushWhiteList() external {
        DAOProxy.delegatedFlushWhiteList(votingDecisionModule);
    }

    function changeWhiteList(address _addr, bool res) external {
        DAOProxy.delegatedChangeWhiteList(votingDecisionModule, _addr, res);
    }

    function withdrawal(address _address, uint withdrawalSum) external {
        DAOProxy.delegatedWithdrawal(votingDecisionModule,_address, withdrawalSum);
    }

    function makeRefundableByUser() external {
        DAOProxy.delegatedMakeRefundableByUser(votingDecisionModule);
    }

    function makeRefundableByVotingDecision() external {
        DAOProxy.delegatedMakeRefundableByVotingDecision(votingDecisionModule);
    }

    function holdTokens(address _address, uint duration) external {
        DAOProxy.delegatedHoldTokens(votingDecisionModule, _address, duration);
    }

    /*
        Payment module related functions
    */

    function getCommissionTokens() {
        DAOProxy.delegatedGetCommissionTokens(paymentModule);
    }

    function refund() {
        DAOProxy.delegatedRefund(paymentModule);
    }

    function refundSoftCap()  {
        DAOProxy.delegatedRefundSoftCap(paymentModule);
    }


    /*
        Create proposal functions
    */
    function addProposal(string _description, uint _duration, bytes32[] _options) {
        votings[DAOLib.delegatedCreateProposal(votingFactory, Common.stringToBytes32(_description), _duration, _options, this)] = true;
    }

    function addWithdrawal(string _description, uint _duration, uint _sum, address withdrawalWallet) {
        votings[DAOLib.delegatedCreateWithdrawal(votingFactory, Common.stringToBytes32(_description), _duration, _sum, withdrawalWallet, this)] = true;
    }

    function addRefund(string _description, uint _duration) {
        votings[DAOLib.delegatedCreateRefund(votingFactory, Common.stringToBytes32(_description), _duration, this)] = true;
    }

    function addWhiteList(string _description, uint _duration, address _addr, uint action) {
        votings[DAOLib.delegatedCreateWhiteList(votingFactory, Common.stringToBytes32(_description), _duration, _addr, action, this)] = true;
    }

    /*
        Setters for module addresses
    */
    function setStateModule(address _stateModule) external canSetModule(stateModule) {
        stateModule = _stateModule;
    }

    function setPaymentModule(address _paymentModule) external canSetModule(paymentModule) {
        paymentModule = _paymentModule;
    }

    function setVotingDecisionModule(address _votingDecisionModule) external canSetModule(votingDecisionModule) {
        votingDecisionModule = _votingDecisionModule;
    }

    function setCrowdsaleModule(address _crowdsaleModule) external canSetModule(crowdsaleModule) {
        crowdsaleModule = _crowdsaleModule;
    }

    /*
        Self functions
    */

    function isParticipant(address _participantAddress) external constant returns (bool) {
        return token.balanceOf(_participantAddress) > 0;
    }

    function initBonuses(address[] _team, uint[] tokenPercents, uint[] _bonusPeriods, uint[] _bonusRates, uint[] _teamHold) onlyOwner(msg.sender) external {
        require(_team.length == tokenPercents.length && _team.length == _teamHold.length && _bonusPeriods.length == _bonusRates.length && canInitBonuses && (block.timestamp < startTime || canInitCrowdsaleParameters));
        team = _team;
        teamHold = _teamHold;
        teamBonusesArr = tokenPercents;
        for(uint i = 0; i < _team.length; i++) {
            teamBonuses[_team[i]] = tokenPercents[i];
        }
        bonusPeriods = _bonusPeriods;
        bonusRates = _bonusRates;

        canInitBonuses = false;
    }

    function setWhiteList(address[] _addresses) onlyOwner(msg.sender) {
        require(canSetWhiteList);

        whiteListArr = _addresses;
        for(uint i = 0; i < _addresses.length; i++) {
            whiteList[_addresses[i]] = true;
        }

        canSetWhiteList = false;
    }

    /*
    Modifiers
    */
    modifier canSetModule(address module) {
        require(votings[msg.sender] || (module == 0x0 && msg.sender == owner));
        _;
    }
}

contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function Ownable() {
        owner = msg.sender;
    }


    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}



library VotingLib {
    enum VotingType {Proposal, Withdrawal, Refund, WhiteList}

    struct Option {
        uint votes;
        bytes32 description;
    }

    function delegatecallCreate(address _v, address dao, bytes32 _description, uint _duration, uint quorum) {
        require(_v.delegatecall(bytes4(keccak256("create(address,bytes32,uint256,uint256)")), dao, _description, _duration, quorum));
    }

    function delegatecallAddVote(address _v, uint optionID) {
        require(_v.delegatecall(bytes4(keccak256("addVote(uint256)")), optionID));
    }

    function delegatecallFinish(address _v) {
        require(_v.delegatecall(bytes4(keccak256("finish()"))));
    }
}
contract IDAO {
    function isParticipant(address _participantAddress) external constant returns (bool);

    function whiteList(address _address) constant returns (bool);

    uint public endTime;
    uint public weiRaised;
    uint public softCap;
}
contract ICrowdsaleDAO is IDAO {
    function addProposal(string _description, uint _duration, bytes32[] _options) external;

    function addWithdrawal(string _description, uint _duration, uint _sum) external;

    function addRefund(string _description, uint _duration) external;

    function makeRefundable();

    function flushWhiteList() external;

    function changeWhiteList(address _addr, bool res) external;

    function holdTokens(address _address, uint duration) external;

    function withdrawal(address _address, uint withdrawalSum);

    function teamBonuses(address _address) returns (uint);

    function token() returns (TokenInterface);
}
contract VotingFields {
    ICrowdsaleDAO dao;
    bytes32 public description;
    VotingLib.Option[10] public options;
    mapping (address => bool) public voted;
    VotingLib.Option public result;
    uint public votesCount;
    uint public duration; // UNIX
    uint public created_at = now;
    bool public finished = false;
    uint public quorum;
    bytes32 public votingType;
}
contract Voting is VotingFields {

    function create(address _dao, bytes32 _description, uint _duration, uint _quorum) succeededCrowdsale(ICrowdsaleDAO(_dao)) external {
        dao = ICrowdsaleDAO(_dao);
        description = _description;
        duration = _duration;
        quorum = _quorum;
    }

    function addVote(uint optionID) external notFinished canVote(optionID) {
        require(block.timestamp - duration < created_at);
        uint tokensAmount = dao.token().balanceOf(msg.sender);
        options[optionID].votes += tokensAmount;
        voted[msg.sender] = true;
        votesCount += tokensAmount;

        dao.holdTokens(msg.sender, (duration + created_at) - now);
    }

    function finish() external notFinished {
        require(block.timestamp - duration >= created_at);
        finished = true;
        if (Common.percent(votesCount, dao.token().totalSupply(), 2) < quorum) return;

        if (keccak256(votingType) == keccak256(bytes32("Proposal"))) finishProposal();
        else finishNotProposal();
    }

    function finishProposal() private {
        VotingLib.Option memory _result = options[0];
        for(uint i = 0; i< options.length; i++) {
            if(_result.votes < options[i].votes) _result = options[i];
        }
        result = _result;
    }

    function finishNotProposal() private {
        if(options[0].votes > options[1].votes) result = options[0];
        else result = options[1];
    }

    function getProposalOptions() public constant returns(bytes32[]) {
        bytes32[] memory optionDescriptions = new bytes32[](options.length);
        for(uint i = 0; i < options.length; i++) {
            optionDescriptions[i] = options[i].description;
        }

        return optionDescriptions;
    }

    modifier canVote(uint optionID) {
        require(dao.teamBonuses(msg.sender) == 0 && dao.isParticipant(msg.sender) && optionID < options.length && !voted[msg.sender]);
        _;
    }

    modifier notFinished() {
        require(!finished);
        _;
    }

    modifier succeededCrowdsale(ICrowdsaleDAO dao) {
        require(block.timestamp >= dao.endTime() && dao.weiRaised() >= dao.softCap());
        _;
    }
}
contract Proposal is VotingFields {
    address baseVoting;

    function Proposal(address _baseVoting, address _dao, bytes32 _description, uint _duration, bytes32[] _options){
        require(_options.length <= 10);
        baseVoting = _baseVoting;
        votingType = "Proposal";
        VotingLib.delegatecallCreate(baseVoting, _dao, _description, _duration, 50);
        createOptions(_options);
    }

    function addVote(uint optionID) {
        VotingLib.delegatecallAddVote(baseVoting, optionID);
    }

    function finish() {
        VotingLib.delegatecallFinish(baseVoting);
    }

    function createOptions(bytes32[] _options) private {
        for (uint i = 0; i < _options.length; i++) {
            options[i] = VotingLib.Option(0, _options[i]);
        }
    }

    function getOptions() external constant returns(uint[] result) {
        for (uint i = 0; i < 10; i++) {
            result[i] = options[i].votes;
        }
    }
}
contract Withdrawal is VotingFields {
    address baseVoting;
    uint public withdrawalSum;
    address public withdrawalWallet;

    function Withdrawal(address _baseVoting, address _dao, bytes32 _description, uint _duration, uint _sum, uint _quorum, address _withdrawalWallet){
        require(_sum > 0 && _sum * 1 ether <= _dao.balance);
        baseVoting = _baseVoting;
        votingType = "Withdrawal";
        VotingLib.delegatecallCreate(baseVoting, _dao, _description, _duration, _quorum);
        withdrawalSum = _sum;
        withdrawalWallet = _withdrawalWallet;
        createOptions();
    }

    function addVote(uint optionID) {
        VotingLib.delegatecallAddVote(baseVoting, optionID);
    }

    function finish() {
        VotingLib.delegatecallFinish(baseVoting);
        if(result.description == "yes") dao.withdrawal(withdrawalWallet, withdrawalSum);
    }

    function createOptions() private {
        options[0] = VotingLib.Option(0, "yes");
        options[1] = VotingLib.Option(0, "no");
    }

    function getOptions() external constant returns(uint[2] result) {
        for (uint i = 0; i < 2; i++) {
            result[i] = options[i].votes;
        }
    }
}
contract Refund is VotingFields {
    address baseVoting;

    function Refund(address _baseVoting, address _dao, bytes32 _description, uint _duration, uint _quorum){
        baseVoting = _baseVoting;
        votingType = "Refund";
        VotingLib.delegatecallCreate(baseVoting, _dao, _description, _duration, _quorum);
        createOptions();
    }

    function addVote(uint optionID) {
        VotingLib.delegatecallAddVote(baseVoting, optionID);
    }

    function finish() {
        VotingLib.delegatecallFinish(baseVoting);
        if(result.description == "yes") dao.makeRefundable();
    }

    function createOptions() private {
        options[0] = VotingLib.Option(0, "yes");
        options[1] = VotingLib.Option(0, "no");
    }
}
contract WhiteList is VotingFields {
    enum Action {Add, Remove, Flush}

    address baseVoting;
    Action action;
    address addr = 0x0;

    function WhiteList(address _baseVoting, address _dao, bytes32 _description, uint _duration, uint _quorum, address _addr, uint _action){
        require(_addr != 0x0 || Action(_action) == Action.Flush);
        baseVoting = _baseVoting;
        votingType = "WhiteList";
        VotingLib.delegatecallCreate(baseVoting, _dao, _description, _duration, _quorum);
        addr = _addr;
        action = Action(_action);
        createOptions();
    }

    function addVote(uint optionID) {
        VotingLib.delegatecallAddVote(baseVoting, optionID);
    }

    function finish() {
        VotingLib.delegatecallFinish(baseVoting);
        bool res = (result.description == "yes");
        if(!res) return;
        if(action == Action.Flush) {
            dao.flushWhiteList();
            return;
        }
        if(action == Action.Remove) res = !res;
        dao.changeWhiteList(addr, res);
    }

    function createOptions() private {
        options[0] = VotingLib.Option(0, "yes");
        options[1] = VotingLib.Option(0, "no");
    }

    function getOptions() external constant returns(uint[2] result) {
        for (uint i = 0; i < 2; i++) {
            result[i] = options[i].votes;
        }
    }
}

contract VotingFactory is VotingFactoryInterface {
    address baseVoting;
    DAOFactoryInterface daoFactory;

    function VotingFactory(address _baseVoting){
        baseVoting = _baseVoting;
    }

    function createProposal(address _creator, bytes32 _description, uint _duration, bytes32[] _options) onlyDAO onlyParticipant(_creator) external returns (address) {
        return new Proposal(baseVoting, msg.sender, _description, _duration, _options);
    }

    function createWithdrawal(address _creator, bytes32 _description, uint _duration, uint _sum, uint quorum, address withdrawalWallet) onlyParticipant(_creator) onlyDAO onlyWhiteList(withdrawalWallet) external returns (address) {
        return new Withdrawal(baseVoting, msg.sender, _description, _duration, _sum, quorum, withdrawalWallet);
    }

    function createRefund(address _creator, bytes32 _description, uint _duration, uint quorum) onlyDAO onlyParticipant(_creator) external returns (address) {
        return new Refund(baseVoting, msg.sender, _description, _duration, quorum);
    }

    function createWhiteList(address _creator, bytes32 _description, uint _duration, uint quorum, address _addr, uint action) onlyDAO onlyParticipant(_creator) external returns (address) {
        return new WhiteList(baseVoting, msg.sender, _description, _duration, quorum, _addr, action);
    }

    function setDaoFactory(address _dao) external {
        require(address(daoFactory) == 0x0 && _dao != 0x0);
        daoFactory = DAOFactoryInterface(_dao);
    }

    modifier onlyDAO() {
        require(daoFactory.exists(msg.sender));
        _;
    }

    modifier onlyParticipant(address creator) {
        require(IDAO(msg.sender).isParticipant(creator));
        _;
    }

    modifier onlyWhiteList(address creator) {
        require(IDAO(msg.sender).whiteList(creator));
        _;
    }
}

contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));

        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) allowed;


    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));

        uint256 _allowance = allowed[_from][msg.sender];

        // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
        // require (_value <= _allowance);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     *
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    /**
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     */
    function increaseApproval (address _spender, uint _addedValue)
    returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval (address _spender, uint _subtractedValue)
    returns (bool success) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract MintableToken is StandardToken, Ownable {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    bool public mintingFinished = false;


    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    /**
     * @dev Function to mint tokens
     * @param _to The address that will receive the minted tokens.
     * @param _amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        Transfer(0x0, _to, _amount);
        return true;
    }

    /**
     * @dev Function to stop minting new tokens.
     * @return True if the operation was successful.
     */
    function finishMinting() onlyOwner public returns (bool) {
        mintingFinished = true;
        MintFinished();
        return true;
    }
}

contract Token is MintableToken {
    event TokenCreation(address _address);

    string public name;
    string public symbol;
    uint constant public decimals = 18;
    mapping(address => uint) public held;


    function Token(string _name, string _symbol)
    {
        name = _name;
        symbol = _symbol;
        TokenCreation(this);
    }

    function hold(address addr, uint duration) onlyOwner external {
        uint holdTime = now + duration;
        if (held[addr] == 0 || holdTime > held[addr]) held[addr] = holdTime;
    }

    function burn(address _burner) onlyOwner external {
        require(_burner != 0x0);

        uint balance = balanceOf(_burner);
        balances[_burner] = balances[_burner].sub(balance);
        totalSupply = totalSupply.sub(balance);
    }

    function transfer(address to, uint256 value) notHolded(msg.sender) public returns (bool) {
        super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) notHolded(from) public returns (bool) {
        super.transferFrom(from, to, value);
    }

    modifier notHolded(address _address) {
        require(held[_address] == 0 || now >= held[_address]);
        _;
    }
}

contract DAOx is Owned {
    Token public token;
    uint public constant tokenRate = 100;
    uint weiRaised;
    DAOFactoryInterface daoFactory;

    function DAOx()
    Owned(msg.sender){
        token = new Token("DAOx", "DAOX");
    }

    function() onlyDAO payable {
        weiRaised = weiRaised + msg.value;
    }

    function setDaoFactory(address _dao, address _creator) onlyOwner(_creator) external {
        require(address(daoFactory) == 0x0 && _dao != 0x0);
        daoFactory = DAOFactoryInterface(_dao);
    }

    function getCommissionTokens(address _address, uint weiSent) onlyDAO external {
        uint tokensAmount = weiSent * tokenRate;
        token.mint(_address, tokensAmount);
    }

    function withdraw(uint sum) onlyOwner(msg.sender) {
        assert(owner.call.value(sum*1 wei)());
    }

    modifier onlyDAO() {
        require(daoFactory.exists(msg.sender));
        _;
    }
}

contract CrowdsaleDAOFactory is DAOFactoryInterface {
    event CrowdsaleDAOCreated(
        address _address,
        string _name
    );

    mapping(address => string) DAOs;
    address public serviceContractAddress;
    address public votingFactoryContractAddress;
    address[4] modules;

    function CrowdsaleDAOFactory(address _serviceContractAddress, address _votingFactoryAddress, address[4] _modules) {
        require(_serviceContractAddress != 0x0 && _votingFactoryAddress != 0x0);
        serviceContractAddress = _serviceContractAddress;
        votingFactoryContractAddress = _votingFactoryAddress;
        modules = _modules;

        require(votingFactoryContractAddress.call(bytes4(keccak256("setDaoFactory(address)")), this));
        require(serviceContractAddress.call(bytes4(keccak256("setDaoFactory(address,address)")), this, msg.sender));
    }

    function createCrowdsaleDAO(string _name, string _description) {
        address dao = DAODeployer.deployCrowdsaleDAO(_name, Common.stringToBytes32(_description));

        require(dao.call(bytes4(keccak256("setStateModule(address)")), modules[0]));
        require(dao.call(bytes4(keccak256("setPaymentModule(address)")), modules[1]));
        require(dao.call(bytes4(keccak256("setVotingDecisionModule(address)")), modules[2]));
        require(dao.call(bytes4(keccak256("setCrowdsaleModule(address)")), modules[3]));
        DAODeployer.transferOwnership(dao, msg.sender);

        DAOs[dao] = _name;
        CrowdsaleDAOCreated(dao, _name);
    }

    function exists(address _address) constant returns (bool) {
        return keccak256(DAOs[_address]) != keccak256("");
    }
}