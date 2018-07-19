pragma solidity 0.4.24;

interface TokenInterface {
	function mint(address _to, uint256 _amount) public returns (bool);
	function finishMinting() public returns (bool);
	function totalSupply() public constant returns (uint);
	function balanceOf(address _address) public constant returns (uint);
	function burn(address burner);
	function hold(address addr, uint duration) external;
	function transfer(address _to, uint _amount) external;
	function contributeTo(address _to, uint256 _amount) public;
}

interface VotingFactoryInterface {
	function createRegular(address _creator, string _name, string _description, uint _duration, bytes32[] _options) external returns (address);

	function createWithdrawal(address _creator, string _name, string _description, uint _duration, uint _sum, address withdrawalWallet, bool _dxc) external returns (address);

	function createRefund(address _creator, string _name, string _description, uint _duration) external returns (address);

	function setDaoFactory(address _dao) external;
}

interface IServiceVotingFactory {
	function createModule(address _creator, string _name, string _description, uint _duration, uint _module, address _newAddress) external returns (address);

	function createNewService(address _creator, string _name, string _description, uint _duration, address _service) external returns (address);

	function createCallService(address _creator, string _name, string _description, uint _duration, address _service, bytes32 _method, bytes32[10] _args) external returns (address);

	function setDaoFactory(address _dao) external;
}

library DAOLib {
	event VotingCreated(
		address voting,
		string votingType,
		address dao,
		string name,
		string description,
		uint duration,
		address sender
	);

	/*
    * @dev Receives parameters from crowdsale module in case of successful crowdsale and processes them
    * @param token Instance of token contract
    * @param commissionRaised Amount of funds which were sent via commission contract
    * @param serviceContract Address of contract which receives commission
    * @param teamBonuses Array of percents which indicates the number of token for every team member
    * @param team Array of team members' addresses
    * @param teamHold Array of timestamp until which the tokens will be held for every team member
    * @return uint Amount of tokens minted for team
    */
	function handleFinishedCrowdsale(TokenInterface token, uint commissionRaised, address serviceContract, uint[] teamBonuses, address[] team, uint[] teamHold) returns (uint) {
		uint totalSupply = token.totalSupply() / 100;
		uint teamTokensAmount = 0;
		for (uint i = 0; i < team.length; i++) {
			uint teamMemberTokensAmount = SafeMath.mul(totalSupply, teamBonuses[i]);
			teamTokensAmount += teamMemberTokensAmount;
			token.mint(team[i], teamMemberTokensAmount);
			token.hold(team[i], teamHold[i]);
		}

		return teamTokensAmount;
	}

	function delegatedCreateRegular(VotingFactoryInterface _votingFactory, string _name, string _description, uint _duration, bytes32[] _options, address _dao) returns (address) {
		address _votingAddress = _votingFactory.createRegular(msg.sender, _name, _description, _duration, _options);
		VotingCreated(_votingAddress, "Regular", _dao, _name, _description, _duration, msg.sender);

		return _votingAddress;
	}

	function delegatedCreateWithdrawal(VotingFactoryInterface _votingFactory, string _name, string _description, uint _duration, uint _sum, address withdrawalWallet, bool _dxc, address _dao)
	returns (address)
	{
		address _votingAddress = _votingFactory.createWithdrawal(msg.sender, _name, _description, _duration, _sum, withdrawalWallet, _dxc);
		VotingCreated(_votingAddress, "Withdrawal", _dao, _name, _description, _duration, msg.sender);

		return _votingAddress;
	}

	function delegatedCreateRefund(VotingFactoryInterface _votingFactory, string _name, string _description, uint _duration, address _dao) returns (address) {
		address _votingAddress = _votingFactory.createRefund(msg.sender, _name, _description, _duration);
		VotingCreated(_votingAddress, "Refund", _dao, _name, _description, _duration, msg.sender);

		return _votingAddress;
	}

	function delegatedCreateModule(IServiceVotingFactory _votingFactory, string _name, string _description, uint _duration, uint _module, address _newAddress, address _dao) returns (address) {
		address _votingAddress = _votingFactory.createModule(msg.sender, _name, _description, _duration, _module, _newAddress);
		VotingCreated(_votingAddress, "Module", _dao, _name, _description, _duration, msg.sender);

		return _votingAddress;
	}

	function delegatedCreateNewService(IServiceVotingFactory _votingFactory, string _name, string _description, uint _duration, address _service, address _dao) returns (address) {
		address _votingAddress = _votingFactory.createNewService(msg.sender, _name, _description, _duration, _service);
		VotingCreated(_votingAddress, "New Service", _dao, _name, _description, _duration, msg.sender);

		return _votingAddress;
	}

	function delegatedCreateCallService(IServiceVotingFactory _votingFactory, string _name, string _description, uint _duration, address _service, bytes32 _method, bytes32[10] _args, address _dao) returns (address) {
		address _votingAddress = _votingFactory.createCallService(msg.sender, _name, _description, _duration, _service, _method, _args);
		VotingCreated(_votingAddress, "Call Service", _dao, _name, _description, _duration, msg.sender);

		return _votingAddress;
	}

	/*
    * @dev Counts the number of tokens that should be minted according to amount of sent funds and current rate
    * @param value Amount of sent funds
    * @param bonusPeriods Array of timestamps indicating bonus periods
    * @param bonusRates Array of rates for every bonus period
    * @param rate Default rate
    * @return uint Amount of tokens that should be minted
    */
	function countTokens(uint value, uint[] bonusPeriods, uint[] bonusRates, uint rate) constant returns (uint) {
		if (bonusRates.length == 0) return value * rate; // DXC bonus rates could be empty

		for (uint i = 0; i < bonusPeriods.length; i++) {
			if (now < bonusPeriods[i]) {
				rate = bonusRates[i];
				break;
			}
		}
		uint tokensAmount = SafeMath.mul(value, rate);

		return tokensAmount;
	}

	/*
    * @dev Counts the amount of funds that must be returned to participant
    * @param tokensAmount Amount of tokens on participant's balance
    * @param etherRate Rate for ether during the crowdsale
    * @param newRate Current rate according to left funds and total supply of tokens
    * @param multiplier Multiplier that was used in previous calculations to avoid issues with float numbers
    * @return uint Amount of funds that must be returned to participant
    */
	function countRefundSum(uint tokensAmount, uint etherRate, uint newRate, uint multiplier) constant returns (uint) {
		uint fromPercentDivider = 100;

		return (tokensAmount * newRate / fromPercentDivider) / (multiplier * etherRate);
	}
}

contract CrowdsaleDAOFields {
	bytes32 constant public version = "1.0.0";
	uint public etherRate;
	uint public DXCRate;
	uint public softCap;
	uint public hardCap;
	uint public startTime;
	uint public endTime;
	bool public canInitCrowdsaleParameters = true;
	bool public canInitStateParameters = true;
	bool public canInitBonuses = true;
	bool public canSetWhiteList = true;
	uint public commissionRaised = 0; // Funds which were provided via commission contract
	uint public weiRaised = 0;
	uint public DXCRaised = 0;
	uint public fundsRaised = 0;
	mapping(address => uint) public depositedWei; // Used for refund in case of not reached soft cap
	mapping(address => uint) public depositedDXC; // Used for refund in case of not reached soft cap
	bool public crowdsaleFinished;
	bool public refundableSoftCap = false;
	uint public newEtherRate = 0; // Used for refund after accept of Refund proposal
	uint public newDXCRate = 0; // Used for refund after accept of Refund proposal
	address public serviceContract; //Contract which gets commission funds if soft cap was reached during the crowdsale
	uint[] public teamBonusesArr;
	address[] public team;
	mapping(address => bool) public teamMap;
	uint[] public teamHold;
	bool[] public teamServiceMember;
	TokenInterface public token;
	VotingFactoryInterface public votingFactory;
	IServiceVotingFactory public serviceVotingFactory;
	address public commissionContract; //Contract that is used to mark funds which were provided through daox.org platform
	string public name;
	string public description;
	uint public created_at = now; // UNIX time
	mapping(address => address) public votings;
	bool public refundable = false;
	uint public lastWithdrawalTimestamp = 0;
	address[] public whiteListArr;
	mapping(address => bool) public whiteList;
	mapping(address => uint) public teamBonuses;
	uint[] public bonusPeriods;
	uint[] public bonusEtherRates;
	uint[] public bonusDXCRates;
	uint public teamTokensAmount;
	uint constant internal withdrawalPeriod = 60 * 60 * 24 * 90;
	TokenInterface public DXC;
	uint public tokensMintedByEther;
	uint public tokensMintedByDXC;
	bool public dxcPayments; //Flag indicating whether it is possible to invest via DXC token or not
	uint public lockup = 0; // UNIX time
	uint public initialCapital = 0;
	uint public votingPrice = 0; // Amount of DXC needed to create voting
	mapping(address => uint) public initialCapitalIncr; // Amount of DXC that user transferred to DAO
	address public proxyAPI;
	mapping(address => bool) public services;
	uint internal constant multiplier = 100000;
	uint internal constant percentMultiplier = 100;
}

contract Owned {
	address public owner;

	function Owned(address _owner) {
		owner = _owner;
	}

	function transferOwnership(address newOwner) onlyOwner(msg.sender) {
		owner = newOwner;
	}

	modifier onlyOwner(address _sender) {
		require(_sender == owner);
		_;
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

	/*
    * @dev Sets addresses of token which will be minted during the crowdsale and address of DXC token contract so that
    *      DAO will be able to handle investments via DXC. Also function creates instance of Commission contract for this DAO
    * @param value Amount of sent funds
    */
	function initState(address _tokenAddress)
	external
	onlyOwner(msg.sender)
	canInit
	crowdsaleNotStarted
	{
		require(_tokenAddress != 0x0);

		token = TokenInterface(_tokenAddress);

		created_at = block.timestamp;

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

	/*
    * @dev Receives info about ether payment from CrowdsaleDAO contract then mints tokens for sender and saves info about
    *      sent funds to either return it in case of refund or get commission from them in case of successful crowdsale
    * @param _sender Address of sender
    * @param _commission Boolean indicating whether it is needed to take commission from sent funds or not
    */
	function handlePayment(address _sender, bool _commission) external payable CrowdsaleIsOngoing validEtherPurchase(msg.value) {
		require(_sender != 0x0);

		uint weiAmount = msg.value;
		if (_commission) {
			commissionRaised = commissionRaised + weiAmount;
		}

		weiRaised += weiAmount;
		depositedWei[_sender] += weiAmount;

		uint tokensAmount = DAOLib.countTokens(weiAmount, bonusPeriods, bonusEtherRates, etherRate);
		tokensMintedByEther = SafeMath.add(tokensMintedByEther, tokensAmount);
		token.mint(_sender, tokensAmount);

		if(lockup > 0) token.hold(_sender, lockup - now);
	}

	/*
    * @dev Receives info about DXC payment from CrowdsaleDAO contract then mints tokens for sender and saves info about
    *      sent funds to return it in case of refund
    * @param _from Address of sender
    * @param _dxcAmount Amount of DXC token which were sent to DAO
    */
	function handleDXCPayment(address _from, uint _dxcAmount) external CrowdsaleIsOngoing validDXCPurchase(_dxcAmount) onlyDXC {
		DXCRaised += _dxcAmount;
		depositedDXC[_from] += _dxcAmount;

		uint tokensAmount = DAOLib.countTokens(_dxcAmount, bonusPeriods, bonusDXCRates, DXCRate);
		tokensMintedByDXC = SafeMath.add(tokensMintedByDXC, tokensAmount);
		token.mint(_from, tokensAmount);

		if(lockup > 0) token.hold(_from, lockup - now);
	}

	/*
    * @dev Sets main parameters for upcoming crowdsale
    * @param _softCap The minimal amount of funds that must be collected by DAO for crowdsale to be considered successful
    * @param _hardCap The maximal amount of funds that can be raised during the crowdsale
    * @param _etherRate Amount of tokens that will be minted per one ether
    * @param _DXCRate Amount of tokens that will be minted per one DXC
    * @param _startTime Unix timestamp that indicates the moment when crowdsale will start
    * @param _endTime Unix timestamp which indicates the moment when crowdsale will end
    * @param _dxcPayments Boolean indicating whether it is possible to invest via DXC token or not
    */
	function initCrowdsaleParameters(uint _softCap, uint _hardCap, uint _etherRate, uint _DXCRate, uint _startTime, uint _endTime, bool _dxcPayments, uint _lockup)
	external
	onlyOwner(msg.sender)
	canInit
	{
		require(_softCap != 0 && _hardCap != 0 && _etherRate != 0 && _DXCRate != 0 && _startTime != 0 && _endTime != 0);
		require(_softCap < _hardCap && _startTime > block.timestamp);
		require(_lockup == 0 || _lockup > _endTime);

		softCap = _softCap * 1 ether;
		hardCap = _hardCap * 1 ether;

		(startTime, endTime, lockup) = (_startTime, _endTime, _lockup);

		(dxcPayments, etherRate, DXCRate) = (_dxcPayments, _etherRate, _DXCRate);

		canInitCrowdsaleParameters = false;
	}

	/*
    * @dev Finishes the crowdsale and analyzes whether it is successful or not. If it is not then DAO goes to refundableSoftCap
    *      state otherwise it counts and mints tokens for team members and holds them for certain period of time according to
    *      parameters which were set for every member via initBonuses function. In addition function sends commission to service contract
    */
	function finish() external {
		fundsRaised = DXCRate != 0 ? weiRaised + (DXCRaised) / (etherRate / DXCRate) : weiRaised;

		require((block.timestamp >= endTime || fundsRaised == hardCap) && !crowdsaleFinished);

		crowdsaleFinished = true;

		if (fundsRaised >= softCap) {
			teamTokensAmount = DAOLib.handleFinishedCrowdsale(token, commissionRaised, serviceContract, teamBonusesArr, team, teamHold);
		} else {
			refundableSoftCap = true;
		}

		token.finishMinting();
	}

	modifier canInit() {
		require(canInitCrowdsaleParameters);
		_;
	}

	modifier onlyCommission() {
		require(commissionContract == msg.sender);
		_;
	}

	modifier CrowdsaleIsOngoing() {
		require(block.timestamp >= startTime && block.timestamp < endTime && !crowdsaleFinished);
		_;
	}

	modifier validEtherPurchase(uint value) {
		require(DXCRate != 0 ?
			hardCap - DXCRaised / (etherRate / DXCRate) >= weiRaised + value :
			hardCap >= weiRaised + value);
		_;
	}

	modifier validDXCPurchase(uint value) {
		require(dxcPayments && (hardCap - weiRaised >= (value + DXCRaised) / (etherRate / DXCRate)));
		_;
	}

	modifier onlyDXC() {
		require(msg.sender == address(DXC));
		_;
	}

	modifier onlyOwner(address _sender) {
		require(_sender == owner);
		_;
	}
}

contract Payment is CrowdsaleDAOFields {
	/*
    * @dev Returns funds to participant according to amount of funds that left in DAO and amount of tokens for this participant
    */
	function refund() whenRefundable notTeamMember {
		uint tokensMintedSum = SafeMath.add(tokensMintedByEther, tokensMintedByDXC);
		uint etherPerDXCRate = SafeMath.mul(tokensMintedByEther, percentMultiplier) / tokensMintedSum;
		uint dxcPerEtherRate = SafeMath.mul(tokensMintedByDXC, percentMultiplier) / tokensMintedSum;

		uint tokensAmount = token.balanceOf(msg.sender);
		token.burn(msg.sender);

		if (etherPerDXCRate != 0)
			msg.sender.transfer(DAOLib.countRefundSum(etherPerDXCRate * tokensAmount, etherRate, newEtherRate, multiplier));

		if (dxcPerEtherRate != 0)
			DXC.transfer(msg.sender, DAOLib.countRefundSum(dxcPerEtherRate * tokensAmount, DXCRate, newDXCRate, multiplier));
	}

	/*
    * @dev Returns funds which were sent to crowdsale contract back to backer and burns tokens that were minted for him
    */
	function refundSoftCap() whenRefundableSoftCap {
		require(depositedWei[msg.sender] != 0 || depositedDXC[msg.sender] != 0);

		token.burn(msg.sender);
		uint weiAmount = depositedWei[msg.sender];
		uint tokensAmount = depositedDXC[msg.sender];

		delete depositedWei[msg.sender];
		delete depositedDXC[msg.sender];

		DXC.transfer(msg.sender, tokensAmount);
		msg.sender.transfer(weiAmount);
	}

	/*
    * @dev Receives info about address which sent DXC tokens to current contract and about amount of sent tokens from
    *       DXC token contract and then increases initial capital of DAO and amount of sent tokens for sender
    * @param _from Address which sent DXC tokens
    * @param _amount Amount of tokens which were sent
    */
	function handleDXCPayment(address _from, uint _dxcAmount) external crowdsaleNotOngoing onlyDXC {
		initialCapital += _dxcAmount;
		initialCapitalIncr[_from] += _dxcAmount;
	}

	modifier crowdsaleNotOngoing() {
		require(
			canInitCrowdsaleParameters || startTime > now || (crowdsaleFinished && !refundableSoftCap),
			"Method can be called only after successful crowdsale or before it"
		);
		_;
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

	modifier notTeamMember() {
		require(!teamMap[msg.sender]);
		_;
	}

	modifier onlyDXC() {
		require(msg.sender == address(DXC), "Method can be called only from DXC contract");
		_;
	}
}

interface IService {
	function priceToConnect() public view returns(uint);

	function priceToCall() public view returns(uint);

	function calledWithVoting(bytes32 method) public view returns(bool);
}

interface IProxyAPI {
	function callService(address _address, bytes32 method, bytes32[10] _bytes) external;
}

contract VotingDecisions is CrowdsaleDAOFields {

	/*
    * @dev Transfers withdrawal sum in ether or DXC tokens to the whitelisted address. Calls from Withdrawal proposal
    * @param _address Whitelisted address
    * @param _withdrawalSum Amount of ether/DXC to be sent
    * @param _dxc Should withdrawal be in DXC tokens
    */
	function withdrawal(address _address, uint _withdrawalSum, bool _dxc) external notInRefundableState onlyVoting {
		lastWithdrawalTimestamp = block.timestamp;
		_dxc ? DXC.transfer(_address, _withdrawalSum) : _address.transfer(_withdrawalSum);
	}

	/*
    * @dev Change DAO's mode to `refundable`. Can be called by any tokenholder
    */
	function makeRefundableByUser() external {
		require(lastWithdrawalTimestamp == 0 && block.timestamp >= created_at + withdrawalPeriod
		|| lastWithdrawalTimestamp != 0 && block.timestamp >= lastWithdrawalTimestamp + withdrawalPeriod);
		makeRefundable();
	}

	/*
    * @dev Change DAO's mode to `refundable`. Calls from Refund proposal
    */
	function makeRefundableByVotingDecision() external onlyVoting {
		makeRefundable();
	}

	/*
    * @dev Change DAO's mode to `refundable`. Calls from this contract `makeRefundableByUser` or `makeRefundableByVotingDecision` functions
    */
	function makeRefundable() private notInRefundableState {
		refundable = true;
		newEtherRate = SafeMath.mul(this.balance * etherRate, multiplier) / tokensMintedByEther;
		newDXCRate = tokensMintedByDXC != 0 ? SafeMath.mul((DXC.balanceOf(this) - initialCapital) * DXCRate, multiplier) / tokensMintedByDXC : 0;
	}

	/*
    * @dev Make tokens of passed address non-transferable for passed period
    * @param _address Address of tokenholder
    * @param _duration Hold's duration in seconds
    */
	function holdTokens(address _address, uint _duration) external onlyVoting {
		token.hold(_address, _duration);
	}

	function connectService(address _service) external validServiceCaller(_service, "connect") validInitialCapital(_service, "connect") {
		payForService(_service, "connect");
		services[_service] = true;
	}

	function callService(address _service, bytes32 _method, bytes32[10] _args) external validServiceCaller(_service, _method) validInitialCapital(_service, "call") {
		payForService(_service, "call");
		IProxyAPI(proxyAPI).callService(_service, _method, _args);
	}

	function payForService(address _service, string action) private {
		uint price = keccak256(action) == keccak256("call") ? IService(_service).priceToCall() : IService(_service).priceToConnect();
		initialCapital -= price;
		DXC.contributeTo(_service, price);
	}

	/*
    * @dev Throws if called not by any voting contract
    */
	modifier onlyVoting() {
		require(votings[msg.sender] != 0x0);
		_;
	}

	/*
    * @dev Throws if DAO is in refundable state
    */
	modifier notInRefundableState {
		require(!refundable && !refundableSoftCap);
		_;
	}

	modifier validInitialCapital(address _service, string action) {
		uint price = keccak256(action) == keccak256("call") ? IService(_service).priceToCall() : IService(_service).priceToConnect();
		require(price <= initialCapital, "Not enough funds to use module");
		_;
	}

	modifier validServiceCaller(address _service, bytes32 _method) {
		bool votingNeeded = canInitCrowdsaleParameters && _method == bytes32("connect") ? false : IService(_service).calledWithVoting(_method);
		require(votingNeeded ? (votings[msg.sender] != 0x0) : true, "Method can be called only via voting");
		_;
	}
}

interface DAOFactoryInterface {
	function exists(address _address) external constant returns (bool);
}

library DAODeployer {
	function deployCrowdsaleDAO(
		string _name,
		string _description,
		address _serviceContractAddress,
		address _votingFactory,
		address _serviceVotingFactory,
		address _DXC,
		uint _initialCapital
	) returns(CrowdsaleDAO dao) {
		dao = new CrowdsaleDAO(_name, _description, _serviceContractAddress, _votingFactory, _serviceVotingFactory, _DXC, _initialCapital);
	}

	function transferOwnership(address _dao, address _newOwner) {
		CrowdsaleDAO(_dao).transferOwnership(_newOwner);
	}
}

library DAOProxy {
	function delegatedInitState(address stateModule, address _tokenAddress) {
		require(stateModule.delegatecall(bytes4(keccak256("initState(address)")), _tokenAddress));
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

	function delegatedWithdrawal(address votingDecisionModule, address _address, uint withdrawalSum, bool dxc) {
		require(votingDecisionModule.delegatecall(bytes4(keccak256("withdrawal(address,uint256,bool)")), _address, withdrawalSum, dxc));
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

	function delegatedInitCrowdsaleParameters(
		address crowdsaleModule,
		uint _softCap,
		uint _hardCap,
		uint _etherRate,
		uint _DXCRate,
		uint _startTime,
		uint _endTime,
		bool _dxcPayments,
		uint _lockup
	) {
		require(crowdsaleModule.delegatecall(bytes4(keccak256("initCrowdsaleParameters(uint256,uint256,uint256,uint256,uint256,uint256,bool,uint256)"))
		, _softCap, _hardCap, _etherRate, _DXCRate, _startTime, _endTime, _dxcPayments, _lockup));
	}

	function delegatedFinish(address crowdsaleModule) {
		require(crowdsaleModule.delegatecall(bytes4(keccak256("finish()"))));
	}

	function delegatedHandlePayment(address crowdsaleModule, address _sender, bool _commission) {
		require(crowdsaleModule.delegatecall(bytes4(keccak256("handlePayment(address,bool)")), _sender, _commission));
	}

	function delegatedHandleDXCPayment(address module, address _from, uint _amount) {
		require(module.delegatecall(bytes4(keccak256("handleDXCPayment(address,uint256)")), _from, _amount));
	}

	function delegatedConnectService(address module, address _service) {
		require(module.delegatecall(bytes4(keccak256("connectService(address)")), _service));
	}

	function delegatedCallService(address module, address _service, bytes32 _method, bytes32[10] _args) {
		require(module.delegatecall(bytes4(keccak256("callService(address,bytes32,bytes32[10])")), _service, _method, _args));
	}
}

library Common {
	function stringToBytes32(string memory source) constant returns (bytes32 result) {
		assembly {
			result := mload(add(source, 32))
		}
	}

	function percent(uint numerator, uint denominator, uint precision) constant returns(uint quotient) {
		uint _numerator  = numerator * 10 ** (precision+1);
		quotient =  ((_numerator / denominator) + 5) / 10;
	}

	function toString(bytes32 _bytes) internal constant returns(string) {
		bytes memory arrayTemp = new bytes(32);
		uint currentLength = 0;

		for (uint i = 0; i < 32; i++) {
			arrayTemp[i] = _bytes[i];
			if (arrayTemp[i] != 0) currentLength+=1;
		}

		bytes memory arrayRes = new bytes(currentLength);
		for (i = 0; i < currentLength; i++) {
			arrayRes[i] = arrayTemp[i];
		}

		return string(arrayRes);
	}
}

contract CrowdsaleDAO is CrowdsaleDAOFields, Owned {
	address public stateModule;
	address public paymentModule;
	address public votingDecisionModule;
	address public crowdsaleModule;
	address public apiSettersModule;

	function CrowdsaleDAO(string _name, string _description, address _serviceContract, address _votingFactory, address _serviceVotingFactory, address _DXC, uint _initialCapital)
	Owned(msg.sender) {
		name = _name;
		description = _description;
		serviceContract = _serviceContract;
		votingFactory = VotingFactoryInterface(_votingFactory);
		serviceVotingFactory = IServiceVotingFactory(_serviceVotingFactory);
		DXC = TokenInterface(_DXC);
		initialCapital = _initialCapital;
		votingPrice = _initialCapital/10 != 0 ? _initialCapital/10 : 1;
	}

	/*
    * @dev Receives ether and forwards to the crowdsale module via a delegatecall with commission flag equal to false
    */
	function() payable {
		DAOProxy.delegatedHandlePayment(crowdsaleModule, msg.sender, false);
	}

	/*
    * @dev Receives ether from commission contract and forwards to the crowdsale module
    *       via a delegatecall with commission flag equal to true
    * @param _sender Address which sent ether to commission contract
    */
	function handleCommissionPayment(address _sender) payable {
		DAOProxy.delegatedHandlePayment(crowdsaleModule, _sender, true);
	}

	/*
    * @dev Receives info about address which sent DXC tokens to current contract and about amount of sent tokens from
    *       DXC token contract and then forwards this data to the crowdsale/payment module
    * @param _from Address which sent DXC tokens
    * @param _amount Amount of tokens which were sent
    */
	function handleDXCPayment(address _from, uint _amount) {
		if(canInitCrowdsaleParameters || now < startTime || (crowdsaleFinished && !refundableSoftCap)) DAOProxy.delegatedHandleDXCPayment(paymentModule, _from, _amount);
		else if(now >= startTime && now <= endTime && !crowdsaleFinished) DAOProxy.delegatedHandleDXCPayment(crowdsaleModule, _from, _amount);
	}

	/*
    * @dev Receives decision from withdrawal voting and forwards it to the voting decisions module
    * @param _address Address for withdrawal
    * @param _withdrawalSum Amount of ether/DXC tokens which must be sent to withdrawal address
    * @param _dxc boolean indicating whether withdrawal should be made through DXC tokens or not
    */
	function withdrawal(address _address, uint _withdrawalSum, bool _dxc) external {
		DAOProxy.delegatedWithdrawal(votingDecisionModule, _address, _withdrawalSum, _dxc);
	}

	/*
    * @dev Receives decision from refund voting and forwards it to the voting decisions module
    */
	function makeRefundableByVotingDecision() external {
		DAOProxy.delegatedMakeRefundableByVotingDecision(votingDecisionModule);
	}

	function connectService(address _service) external {
		DAOProxy.delegatedConnectService(votingDecisionModule, _service);
	}

	function callService(address _service, bytes32 _method, bytes32[10] _args) external {
		DAOProxy.delegatedCallService(votingDecisionModule, _service, _method, _args);
	}

	/*
    * @dev Called by voting contract to hold tokens of voted address.
    *      It is needed to prevent multiple votes with same tokens
    * @param _address Voted address
    * @param _duration Amount of time left for voting to be finished
    */
	function holdTokens(address _address, uint _duration) external {
		DAOProxy.delegatedHoldTokens(votingDecisionModule, _address, _duration);
	}

	function setStateModule(address _stateModule) external canSetAddress(stateModule) {
		stateModule = _stateModule;
	}

	function setPaymentModule(address _paymentModule) external canSetAddress(paymentModule) {
		paymentModule = _paymentModule;
	}

	function setVotingDecisionModule(address _votingDecisionModule) external canSetAddress(votingDecisionModule) {
		votingDecisionModule = _votingDecisionModule;
	}

	function setCrowdsaleModule(address _crowdsaleModule) external canSetAddress(crowdsaleModule) {
		crowdsaleModule = _crowdsaleModule;
	}

	function setVotingFactoryAddress(address _votingFactory) external canSetAddress(votingFactory) {
		votingFactory = VotingFactoryInterface(_votingFactory);
	}

	function setProxyAPI(address _proxyAPI) external canSetAddress(proxyAPI) {
		proxyAPI = _proxyAPI;
	}

	function setApiSettersModule(address _apiSettersModule) external canSetAddress(apiSettersModule) {
		apiSettersModule = _apiSettersModule;
	}

	function setServiceVotingFactory(address _serviceVotingFactory) external canSetAddress(serviceVotingFactory) {
		serviceVotingFactory = IServiceVotingFactory(_serviceVotingFactory);
	}

	/*
    * @dev Checks if provided address has tokens of current DAO
    * @param _participantAddress Address of potential participant
    * @return boolean indicating if the address has at least one token
    */
	function isParticipant(address _participantAddress) external constant returns (bool) {
		return token.balanceOf(_participantAddress) > 0;
	}

	/*
    * @dev Function which is used to set address of token which will be distributed by DAO during the crowdsale and
    *      address of DXC token contract to use it for handling payment operations with DXC. Delegates call to state module
    * @param _tokenAddress Address of token which will be distributed during the crowdsale
    * @param _DXC Address of DXC contract
    */
	function initState(address _tokenAddress) public {
		DAOProxy.delegatedInitState(stateModule, _tokenAddress);
	}

	/*
    * @dev Delegates parameters which describe conditions of crowdsale to the crowdsale module.
    * @param _softCap The minimal amount of funds that must be collected by DAO for crowdsale to be considered successful
    * @param _hardCap The maximal amount of funds that can be raised during the crowdsale
    * @param _etherRate Amount of tokens that will be minted per one ether
    * @param _DXCRate Amount of tokens that will be minted per one DXC
    * @param _startTime Unix timestamp that indicates the moment when crowdsale will start
    * @param _endTime Unix timestamp that indicates the moment when crowdsale will end
    * @param _dxcPayments Boolean indicating whether it is possible to invest via DXC token or not
    */
	function initCrowdsaleParameters(uint _softCap, uint _hardCap, uint _etherRate, uint _DXCRate, uint _startTime, uint _endTime, bool _dxcPayments, uint _lockup) public {
		DAOProxy.delegatedInitCrowdsaleParameters(crowdsaleModule, _softCap, _hardCap, _etherRate, _DXCRate, _startTime, _endTime, _dxcPayments, _lockup);
	}

	/*
    * @dev Delegates request of creating "regular" voting and saves the address of created voting contract to votings list
    * @param _name Name for voting
    * @param _description Description for voting that will be created
    * @param _duration Time in seconds from current moment until voting will be finished
    * @param _options List of options
    */
	function addRegular(string _name, string _description, uint _duration, bytes32[] _options) public {
		address voting = DAOLib.delegatedCreateRegular(votingFactory, _name, _description, _duration, _options, this);
		handleCreatedVoting(voting);
	}

	/*
    * @dev Delegates request of creating "withdrawal" voting and saves the address of created voting contract to votings list
    * @param _name Name for voting
    * @param _description Description for voting that will be created
    * @param _duration Time in seconds from current moment until voting will be finished
    * @param _sum Amount of funds that is supposed to be withdrawn
    * @param _withdrawalWallet Address for withdrawal
    * @param _dxc Boolean indicating whether withdrawal must be in DXC tokens or in ether
    */
	function addWithdrawal(string _name, string _description, uint _duration, uint _sum, address _withdrawalWallet, bool _dxc) public {
		votings[DAOLib.delegatedCreateWithdrawal(votingFactory, _name, _description, _duration, _sum, _withdrawalWallet, _dxc, this)] = msg.sender;
	}

	/*
    * @dev Delegates request of creating "refund" voting and saves the address of created voting contract to votings list
    * @param _name Name for voting
    * @param _description Description for voting that will be created
    * @param _duration Time in seconds from current moment until voting will be finished
    */
	function addRefund(string _name, string _description, uint _duration) public {
		address voting = DAOLib.delegatedCreateRefund(votingFactory, _name, _description, _duration, this);
		handleCreatedVoting(voting);
	}

	/*
    * @dev Delegates request of creating "module" voting and saves the address of created voting contract to votings list
    * @param _name Name for voting
    * @param _description Description for voting that will be created
    * @param _duration Time in seconds from current moment until voting will be finished
    * @param _module Number of module which must be replaced
    * @param _newAddress Address of new module
    */
	function addModule(string _name, string _description, uint _duration, uint _module, address _newAddress) public {
		address voting = DAOLib.delegatedCreateModule(serviceVotingFactory, _name, _description, _duration, _module, _newAddress, this);
		handleCreatedVoting(voting);
	}

	/*
    * @dev Delegates request of creating "new service" voting and saves the address of created voting contract to votings list
    * @param _name Name for voting
    * @param _description Description for voting that will be created
    * @param _duration Time in seconds from current moment until voting will be finished
    * @param _service Address of service that needs to be connected to DAO
    */
	function addNewService(string _name, string _description, uint _duration, address _service) public {
		address voting = DAOLib.delegatedCreateNewService(serviceVotingFactory, _name, _description, _duration, _service, this);
		handleCreatedVoting(voting);
	}

	/*
    * @dev Delegates request of creating "call service" voting and saves the address of created voting contract to votings list
    * @param _name Name for voting
    * @param _description Description for voting that will be created
    * @param _duration Time in seconds from current moment until voting will be finished
    * @param _service Address of service that needs to be called
    * @param _method Method that must be called in service
    * @param _args Arguments that will be provided to called method
    */
	function addCallService(string _name, string _description, uint _duration, address _service, bytes32 _method, bytes32[10] _args) public {
		address voting = DAOLib.delegatedCreateCallService(serviceVotingFactory, _name, _description, _duration, _service, _method, _args, this);
		handleCreatedVoting(voting);
	}

	/*
    * @dev Delegates request for going into refundable state to voting decisions module
    */
	function makeRefundableByUser() public {
		DAOProxy.delegatedMakeRefundableByUser(votingDecisionModule);
	}

	/*
    * @dev Delegates request for refund to payment module
    */
	function refund() public {
		DAOProxy.delegatedRefund(paymentModule);
	}

	/*
    * @dev Delegates request for refund of soft cap to payment module
    */
	function refundSoftCap() public {
		DAOProxy.delegatedRefundSoftCap(paymentModule);
	}

	/*
    * @dev Delegates request for finish of crowdsale to crowdsale module
    */
	function finish() public {
		DAOProxy.delegatedFinish(crowdsaleModule);
	}

	/*
    * @dev Sets team addresses and bonuses for crowdsale
    * @param _team The addresses that will be defined as team members
    * @param _tokenPercents Array of bonuses in percents which will go te every member in case of successful crowdsale
    * @param _bonusPeriods Array of timestamps which show when tokens will be minted with higher rate
    * @param _bonusEtherRates Array of ether rates for every bonus period
    * @param _bonusDXCRates Array of DXC rates for every bonus period
    * @param _teamHold Array of timestamps which show the hold duration of tokens for every team member
    * @param service Array of booleans which show whether member is a service address or not
    */
	function initBonuses(address[] _team, uint[] _tokenPercents, uint[] _bonusPeriods, uint[] _bonusEtherRates, uint[] _bonusDXCRates, uint[] _teamHold, bool[] _service) public onlyOwner(msg.sender) {
		require(
			_team.length == _tokenPercents.length &&
			_team.length == _teamHold.length &&
			_team.length == _service.length &&
			_bonusPeriods.length == _bonusEtherRates.length &&
		(_bonusDXCRates.length == 0 || _bonusPeriods.length == _bonusDXCRates.length) &&
		canInitBonuses &&
		(block.timestamp < startTime || canInitCrowdsaleParameters)
		);

		team = _team;
		teamHold = _teamHold;
		teamBonusesArr = _tokenPercents;
		teamServiceMember = _service;

		for(uint i = 0; i < _team.length; i++) {
			teamMap[_team[i]] = true;
			teamBonuses[_team[i]] = _tokenPercents[i];
		}

		bonusPeriods = _bonusPeriods;
		bonusEtherRates = _bonusEtherRates;
		bonusDXCRates = _bonusDXCRates;

		canInitBonuses = false;
	}

	/*
    * @dev Sets addresses which can be used to get funds via withdrawal votings
    * @param _addresses Array of addresses which will be used for withdrawals
    */
	function setWhiteList(address[] _addresses) public onlyOwner(msg.sender) {
		require(canSetWhiteList);

		whiteListArr = _addresses;
		for(uint i = 0; i < _addresses.length; i++) {
			whiteList[_addresses[i]] = true;
		}

		canSetWhiteList = false;
	}

	function handleAPICall(string signature, bytes32 value) external onlyProxyAPI {
		require(apiSettersModule.delegatecall(bytes4(keccak256(signature)), value));
	}

	function handleCreatedVoting(address _voting) private {
		votings[_voting] = msg.sender;
		initialCapitalIncr[msg.sender] -= votingPrice;
	}

	/*
    Modifiers
    */

	modifier canSetAddress(address module) {
		require(votings[msg.sender] != 0x0 || (module == 0x0 && msg.sender == owner));
		_;
	}

	modifier onlyProxyAPI() {
		require(msg.sender == proxyAPI, "Method can be called only by ProxyAPI contract");
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
	struct Option {
		uint votes;
		bytes32 description;
	}

	function delegatecallCreate(address _v, address _dao, string _name, string _description, uint _duration, uint _quorum) {
		require(_v.delegatecall(bytes4(keccak256("create(address,bytes32,bytes32,uint256,uint256)")),
			_dao,
			Common.stringToBytes32(_name),
			Common.stringToBytes32(_description),
			_duration,
			_quorum)
		);
	}

	function delegatecallAddVote(address _v, uint optionID) {
		require(_v.delegatecall(bytes4(keccak256("addVote(uint256)")), optionID));
	}

	function delegatecallFinish(address _v) {
		require(_v.delegatecall(bytes4(keccak256("finish()"))));
	}

	function isValidWithdrawal(address _dao, uint _sum, bool _dxc) constant returns(bool) {
		return !_dxc ? _dao.balance >= _sum  : (ICrowdsaleDAO(_dao).DXC().balanceOf(_dao) - ICrowdsaleDAO(_dao).initialCapital()) >= _sum;
	}

	function checkServicePrice(string action, address _dao, address _service) internal {
		uint price = keccak256(action) == keccak256("call") ? IService(_service).priceToCall() : IService(_service).priceToConnect();
		require(price <= ICrowdsaleDAO(_dao).initialCapital(), "Not enough DXC in initial capital to connect this service");
	}

	function serviceConnected(address _dao, address _service) view returns(bool) {
		return ICrowdsaleDAO(_dao).services(_service);
	}
}

contract IDAO {
	function isParticipant(address _participantAddress) external constant returns (bool);

	function teamMap(address _address) external constant returns (bool);

	function whiteList(address _address) constant returns (bool);

	function initialCapitalIncr(address _address) constant returns (uint);

	function votingPrice() constant returns (uint);
}

contract ICrowdsaleDAO is IDAO {
	bool public crowdsaleFinished;
	uint public teamTokensAmount;
	uint public endTime;
	uint public weiRaised;
	uint public softCap;
	uint public fundsRaised;
	uint public initialCapital;

	function addRegular(string _description, uint _duration, bytes32[] _options) external;

	function addWithdrawal(string _description, uint _duration, uint _sum) external;

	function addRefund(string _description, uint _duration) external;

	function addModule(string _description, uint _duration, uint _module, address _newAddress) external;

	function holdTokens(address _address, uint duration) external;

	function makeRefundableByVotingDecision();

	function withdrawal(address _address, uint withdrawalSum, bool dxc);

	function connectService(address _service);

	function setStateModule(address _stateModule);

	function setPaymentModule(address _paymentModule);

	function setVotingDecisionModule(address _votingDecisionModule);

	function setCrowdsaleModule(address _crowdsaleModule);

	function setVotingFactoryAddress(address _votingFactory);

	function teamBonuses(address _address) constant returns (uint);

	function token() constant returns (TokenInterface);

	function DXC() constant returns(TokenInterface);

	function callService(address _service, bytes32 _method, bytes32[10] _args) external;

	function services(address _service) public returns(bool);
}

contract VotingFields {
	ICrowdsaleDAO dao;
	string public name;
	string public description;
	VotingLib.Option[11] public options;
	mapping (address => uint) public voted;
	VotingLib.Option public result;
	uint public votesCount;
	uint public duration; // UNIX
	uint public created_at = now;
	bool public finished = false;
	uint public quorum;
	string public votingType;
	uint public minimalDuration = 60 * 60 * 24 * 7; // 7 days
}

interface VotingInterface {
	function addVote(uint optionID) external;

	function finish() external;

	function getOptions() external constant returns(uint[2] result);

	function finished() external constant returns(bool);

	function voted(address _address) external constant returns (uint);
}

contract BaseProposal is VotingFields {
	address baseVoting;

	/*
    * @dev Returns amount of votes for `yes` and `no` options
    */
	function getOptions() public constant returns(uint[2]) {
		return [options[1].votes, options[2].votes];
	}

	/*
    * @dev Delegates request of adding vote to the Voting base contract
    * @param _optionID ID of option which will be added as vote
    */
	function addVote(uint _optionID) public {
		VotingLib.delegatecallAddVote(baseVoting, _optionID);
	}

	/*
    * @dev Initiates options `yes` and `no`
    */
	function createOptions() internal {
		options[1] = VotingLib.Option(0, "yes");
		options[2] = VotingLib.Option(0, "no");
	}
}

contract Regular is VotingFields {
	address baseVoting;

	function Regular(address _baseVoting, address _dao, string _name, string _description, uint _duration, bytes32[] _options){
		require(_options.length >= 2 && _options.length <= 10);
		baseVoting = _baseVoting;
		votingType = "Regular";
		VotingLib.delegatecallCreate(baseVoting, _dao, _name, _description, _duration, 0);
		createOptions(_options);
	}

	/*
    * @dev Returns amount of votes for all regular proposal's options
    * @return Array[10] of int
    */
	function getOptions() external constant returns(uint[10]) {
		return [options[1].votes, options[2].votes, options[3].votes, options[4].votes, options[5].votes,
		options[6].votes, options[7].votes, options[8].votes, options[9].votes, options[10].votes];
	}

	/*
    * @dev Delegates request of adding vote to the Voting base contract
    * @param _optionID ID of option which will be added as vote
    */
	function addVote(uint _optionID) public {
		VotingLib.delegatecallAddVote(baseVoting, _optionID);
	}

	/*
    * @dev Delegates request of finishing to the Voting base contract
    */
	function finish() public {
		VotingLib.delegatecallFinish(baseVoting);
	}

	/*
    * @dev Creates up to 10 options of votes
    * @param _options Array of votes options
    */
	function createOptions(bytes32[] _options) private {
		for (uint i = 0; i < _options.length; i++) {
			options[i + 1] = VotingLib.Option(0, _options[i]);
		}
	}
}

contract Withdrawal is BaseProposal {
	uint public withdrawalSum;
	address public withdrawalWallet;
	bool public dxc;

	function Withdrawal(address _baseVoting, address _dao, string _name, string _description, uint _duration, uint _sum, address _withdrawalWallet, bool _dxc) {
		require(_sum > 0 && VotingLib.isValidWithdrawal(_dao, _sum, _dxc));
		baseVoting = _baseVoting;
		votingType = "Withdrawal";
		VotingLib.delegatecallCreate(baseVoting, _dao, _name, _description, _duration, 0);
		withdrawalSum = _sum;
		withdrawalWallet = _withdrawalWallet;
		dxc = _dxc;
		createOptions();
	}

	/*
    * @dev Delegates request of finishing to the Voting base contract
    */
	function finish() public {
		VotingLib.delegatecallFinish(baseVoting);
		if(result.description == "yes") dao.withdrawal(withdrawalWallet, withdrawalSum, dxc);
	}
}

contract Refund is BaseProposal {
	function Refund(address _baseVoting, address _dao, string _name, string _description, uint _duration) {
		baseVoting = _baseVoting;
		votingType = "Refund";
		VotingLib.delegatecallCreate(baseVoting, _dao, _name, _description, _duration, 90);
		createOptions();
	}

	function finish() public {
		VotingLib.delegatecallFinish(baseVoting);
		if(result.description == "yes") dao.makeRefundableByVotingDecision();
	}
}

contract Voting is VotingFields {

	/*
    * @dev Initiate storage variables for caller contract via `delegatecall`
    * @param _dao Address of dao where voting is creating
    * @param _name Voting name
    * @param _description Voting description
    * @param _duration Voting duration
    * @param _quorum Minimal percentage of token holders who must to take part in voting
    */
	function create(address _dao, bytes32 _name, bytes32 _description, uint _duration, uint _quorum)
	succeededCrowdsale(ICrowdsaleDAO(_dao))
	correctDuration(_duration)
	external
	{
		dao = ICrowdsaleDAO(_dao);
		name = Common.toString(_name);
		description = Common.toString(_description);
		duration = _duration;
		quorum = _quorum;
	}

	/*
    * @dev Add vote with passed optionID for the caller voting via `delegatecall`
    * @param _optionID ID of option
    */
	function addVote(uint _optionID) external notFinished canVote correctOption(_optionID) {
		require(block.timestamp - duration < created_at);
		uint tokensAmount = dao.token().balanceOf(msg.sender);
		options[_optionID].votes += tokensAmount;
		voted[msg.sender] = _optionID;
		votesCount += tokensAmount;

		dao.holdTokens(msg.sender, (duration + created_at) - now);
	}

	/*
    * @dev Finish voting for the caller voting contract via `delegatecall`
    * @param _optionID ID of option
    */
	function finish() external notFinished {
		require(block.timestamp - duration >= created_at);
		finished = true;


		if (keccak256(votingType) == keccak256("Withdrawal")) return finishNotRegular();
		if (keccak256(votingType) == keccak256("Regular")) return finishRegular();

		//Other two cases of votings (`Module` and `Refund`) requires quorum
		if (Common.percent(options[1].votes, dao.token().totalSupply() - dao.teamTokensAmount(), 2) >= quorum) {
			result = options[1];
			return;
		}

		result = options[2];
	}

	/*
    * @dev Finish regular voting. Calls from `finish` function
    */
	function finishRegular() private {
		VotingLib.Option memory _result = options[1];
		bool equal = false;
		for (uint i = 2; i < options.length; i++) {
			if (_result.votes == options[i].votes) equal = true;
			else if (_result.votes < options[i].votes) {
				_result = options[i];
				equal = false;
			}
		}
		if (!equal) result = _result;
	}

	/*
    * @dev Finish non-regular voting. Calls from `finish` function
    */
	function finishNotRegular() private {
		if (options[1].votes > options[2].votes) result = options[1];
		else result = options[2];
	}

	/*
    * @dev Throws if caller is team member, not participant or has voted already
    */
	modifier canVote() {
		require(!dao.teamMap(msg.sender) && dao.isParticipant(msg.sender) && voted[msg.sender] == 0);
		_;
	}

	/*
    * @dev Throws if voting is finished already
    */
	modifier notFinished() {
		require(!finished);
		_;
	}

	/*
    * @dev Throws if crowdsale is not finished or if soft cap is not achieved
    */
	modifier succeededCrowdsale(ICrowdsaleDAO dao) {
		require(dao.crowdsaleFinished() && dao.fundsRaised() >= dao.softCap());
		_;
	}

	/*
    * @dev Throws if description of provided option ID is empty
    */
	modifier correctOption(uint optionID) {
		require(options[optionID].description != 0x0);
		_;
	}

	/*
    * @dev Throws if passed voting duration is not greater than minimal
    */
	modifier correctDuration(uint _duration) {
		require(_duration >= minimalDuration || keccak256(votingType) == keccak256("Module"));
		_;
	}
}

contract Module is BaseProposal {
	enum Modules{State, Payment, VotingDecisions, Crowdsale, VotingFactory}
	Modules public module;
	address public newModuleAddress;

	function Module(address _baseVoting, address _dao, string _name, string _description, uint _duration, uint _module, address _newAddress) {
		require(_module >= 0 && _module <= 4);
		baseVoting = _baseVoting;
		votingType = "Module";
		module = Modules(_module);
		newModuleAddress = _newAddress;
		VotingLib.delegatecallCreate(baseVoting, _dao, _name, _description, _duration, 80);
		createOptions();
	}

	/*
    * @dev Delegates request of finishing to the Voting base contract
    */
	function finish() public {
		VotingLib.delegatecallFinish(baseVoting);
		if(result.description == "no") return;

		//Sorry but solidity doesn't support `switch` keyword
		if (uint(module) == uint(Modules.State)) dao.setStateModule(newModuleAddress);
		if (uint(module) == uint(Modules.Payment)) dao.setPaymentModule(newModuleAddress);
		if (uint(module) == uint(Modules.VotingDecisions)) dao.setVotingDecisionModule(newModuleAddress);
		if (uint(module) == uint(Modules.Crowdsale)) dao.setCrowdsaleModule(newModuleAddress);
		if (uint(module) == uint(Modules.VotingFactory)) dao.setVotingFactoryAddress(newModuleAddress);
	}
}

contract NewService is BaseProposal {
	address public service;

	function NewService(address _baseVoting, address _dao, string _name, string _description, uint _duration, address _service) {
		VotingLib.checkServicePrice("connect", _dao, _service);
		baseVoting = _baseVoting;
		service = _service;
		VotingLib.delegatecallCreate(baseVoting, _dao, _name, _description, _duration, 80);
		createOptions();
	}

	/*
    * @dev Delegates request of finishing to the Voting base contract
    */
	function finish() public {
		VotingLib.delegatecallFinish(baseVoting);
		if(result.description == "yes") dao.connectService(service);
	}
}

contract CallService is BaseProposal {
	address public service;
	bytes32 public method;
	bytes32[10] public args;

	function CallService(address _baseVoting, address _dao, string _name, string _description, uint _duration, address _service, bytes32 _method, bytes32[10] _args) {
		require(VotingLib.serviceConnected(_dao, _service), "Service must be connected to call it");
		VotingLib.checkServicePrice("call", _dao, _service);
		baseVoting = _baseVoting;
		service = _service;
		method = _method;
		args = _args;
		VotingLib.delegatecallCreate(baseVoting, _dao, _name, _description, _duration, 80);
		createOptions();
	}

	/*
    * @dev Delegates request of finishing to the Voting base contract
    */
	function finish() public {
		VotingLib.delegatecallFinish(baseVoting);
		if(result.description == "yes") dao.callService(service, method, args);
	}
}

contract BaseVotingFactory {
	address baseVoting;
	DAOFactoryInterface public daoFactory;

	constructor(address _baseVoting) public {
		baseVoting = _baseVoting;
	}

	/*
    * @dev Set dao factory address. Calls ones from just deployed DAO
    * @param _dao Address of dao factory
    */
	function setDaoFactory(address _dao) external {
		require(address(daoFactory) == 0x0 && _dao != 0x0);
		daoFactory = DAOFactoryInterface(_dao);
	}

	/*
    * @dev Throws if caller is not correct DAO
    */
	modifier onlyDAO() {
		require(daoFactory.exists(msg.sender));
		_;
	}

	/*
    * @dev Throws if creator is not participant of passed DAO
    */
	modifier onlyParticipantWithEnoughDXC(address creator) {
		require(IDAO(msg.sender).isParticipant(creator), "You need to be a participant to call this method");
		require(IDAO(msg.sender).initialCapitalIncr(creator) >= IDAO(msg.sender).votingPrice(), "You don't have enough DXC to call this method.");
		_;
	}
}

contract VotingFactory is VotingFactoryInterface, BaseVotingFactory {

	constructor(address _baseVoting) BaseVotingFactory(_baseVoting) {}

	/*
    * @dev Create regular proposal with passed parameters. Calls from DAO contract
    * @param _creator Address of caller of DAO's respectively function
    * @param _name Voting's name
    * @param _description Voting's description
    * @param _duration Voting's duration
    * @param _options Voting's options
    */
	function createRegular(address _creator, string _name, string _description, uint _duration, bytes32[] _options)
	external
	onlyDAO
	onlyParticipantWithEnoughDXC(_creator)
	returns (address)
	{
		return new Regular(baseVoting, msg.sender, _name, _description, _duration, _options);
	}

	/*
    * @dev Create withdrawal proposal with passed parameters. Calls from DAO contract
    * @param _creator Address of caller of DAO's respectively function
    * @param _name Voting's name
    * @param _description Voting's description
    * @param _duration Voting's duration
    * @param _sum Sum to withdraw from DAO
    * @param _withdrawalWallet Address to send withdrawal sum
    * @param _dxc Should withdrawal sum be interpret as amount of DXC tokens
    */
	function createWithdrawal(address _creator, string _name, string _description, uint _duration, uint _sum, address _withdrawalWallet, bool _dxc)
	external
	onlyTeamMember(_creator)
	onlyDAO
	onlyWhiteList(_withdrawalWallet)
	returns (address)
	{
		return new Withdrawal(baseVoting, msg.sender, _name, _description, _duration, _sum, _withdrawalWallet, _dxc);
	}

	/*
    * @dev Create refund proposal with passed parameters. Calls from DAO contract
    * @param _creator Address of caller of DAO's respectively function
    * @param _name Voting's name
    * @param _description Voting's description
    * @param _duration Voting's duration
    */
	function createRefund(address _creator, string _name, string _description, uint _duration) external onlyDAO onlyParticipantWithEnoughDXC(_creator) returns (address) {
		return new Refund(baseVoting, msg.sender, _name, _description, _duration);
	}

	/*
    * @dev Throws if creator is not team member of passed DAO
    */
	modifier onlyTeamMember(address creator) {
		require(IDAO(msg.sender).teamMap(creator));
		_;
	}

	/*
    * @dev Throws if creator is not member of white list in specified DAO
    */
	modifier onlyWhiteList(address creator) {
		require(IDAO(msg.sender).whiteList(creator));
		_;
	}
}

contract ServiceVotingFactory is BaseVotingFactory {

	constructor(address _baseVoting) BaseVotingFactory(_baseVoting) {}

	/*
    * @dev Create module proposal with passed parameters. Calls from DAO contract
    * @param _creator Address of caller of DAO's respectively function
    * @param _name Voting's name
    * @param _description Voting's description
    * @param _duration Voting's duration
    * @param _module Which module should be changed
    * @param _newAddress Address of new module
    */
	function createModule(address _creator, string _name, string _description, uint _duration, uint _module, address _newAddress)
	external
	onlyDAO
	onlyParticipantWithEnoughDXC(_creator)
	returns (address)
	{
		return new Module(baseVoting, msg.sender, _name, _description, _duration, _module, _newAddress);
	}

	/*
    * @dev Create new service proposal with passed parameters. Calls from DAO contract
    * @param _creator Address of caller of DAO's respectively function
    * @param _name Voting's name
    * @param _description Voting's description
    * @param _duration Voting's duration
    * @param _service Address of new service
    */
	function createNewService(address _creator, string _name, string _description, uint _duration, address _service)
	external
	onlyDAO
	onlyParticipantWithEnoughDXC(_creator)
	returns (address)
	{
		return new NewService(baseVoting, msg.sender, _name, _description, _duration, _service);
	}

	/*
    * @dev Create call service proposal with passed parameters. Calls from DAO contract
    * @param _creator Address of caller of DAO's respectively function
    * @param _name Voting's name
    * @param _description Voting's description
    * @param _duration Voting's duration
    * @param _service Address of service
    * @param _service Method inside service
    * @param _service Arguments for provided method
    */
	function createCallService(address _creator, string _name, string _description, uint _duration, address _service, bytes32 _method, bytes32[10] _args)
	external
	onlyDAO
	onlyParticipantWithEnoughDXC(_creator)
	returns (address)
	{
		return new CallService(baseVoting, msg.sender, _name, _description, _duration, _service, _method, _args);
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

	function Token(string _name, string _symbol) {
		name = _name;
		symbol = _symbol;
		TokenCreation(this);
	}

	function hold(address addr, uint duration) external onlyOwner {
		uint holdTime = now + duration;
		if (held[addr] == 0 || holdTime > held[addr]) held[addr] = holdTime;
	}

	function burn(address _burner) external onlyOwner {
		require(_burner != 0x0);

		uint balance = balanceOf(_burner);
		balances[_burner] = balances[_burner].sub(balance);
		totalSupply = totalSupply.sub(balance);
	}

	function transfer(address to, uint256 value) public notHolded(msg.sender) returns (bool) {
		return super.transfer(to, value);
	}

	function transferFrom(address from, address to, uint256 value) public notHolded(from) returns (bool) {
		return super.transferFrom(from, to, value);
	}

	modifier notHolded(address _address) {
		require(held[_address] == 0 || now >= held[_address]);
		_;
	}
}

contract DAOx is Ownable {
	uint public balance;
	DAOFactoryInterface public daoFactory;

	function DAOx() {

	}

	function() payable onlyDAO {
		balance += msg.value;
	}

	function setDaoFactory(address _dao) external {
		require(address(daoFactory) == 0x0 && _dao != 0x0);
		daoFactory = DAOFactoryInterface(_dao);
	}

	function withdraw(uint _weiToWithdraw) public onlyOwner {
		balance -= _weiToWithdraw;
		msg.sender.transfer(_weiToWithdraw);
	}

	modifier onlyDAO() {
		require(daoFactory.exists(msg.sender));
		_;
	}
}

interface IDAOModules {
	function setStateModule(address _stateModule) external;
	function setPaymentModule(address _paymentModule) external;
	function setVotingDecisionModule(address _votingDecisionModule) external;
	function setCrowdsaleModule(address _crowdsaleModule) external;
	function setProxyAPI(address _proxyAPI) external;
	function setApiSettersModule(address _allowedSetters) external;
}

contract CrowdsaleDAOFactory is DAOFactoryInterface {
	event CrowdsaleDAOCreated(
		address _address,
		string _name
	);

	address public serviceContractAddress;
	address public votingFactory;
	address public serviceVotingFactory;
	address public DXC;
	mapping(address => uint) DXCDeposit;
	// DAOs created by factory
	mapping(address => string) DAOs;
	// Functional modules which will be used by DAOs to delegate calls
	address[6] modules;

	function CrowdsaleDAOFactory(address _serviceContract, address _votingFactory, address _serviceVotingFactory, address _DXC, address[6] _modules) {
		require(_serviceContract != 0x0 && _votingFactory != 0x0 && _serviceVotingFactory != 0x0 && _DXC != 0x0);
		serviceContractAddress = _serviceContract;
		DXC = _DXC;
		votingFactory = _votingFactory;
		serviceVotingFactory = _serviceVotingFactory;
		modules = _modules;

		require(votingFactory.call(bytes4(keccak256("setDaoFactory(address)")), this));
		require(serviceVotingFactory.call(bytes4(keccak256("setDaoFactory(address)")), this));
		require(serviceContractAddress.call(bytes4(keccak256("setDaoFactory(address)")), this));
	}

	/*
    * @dev Checks if provided address is an address of some DAO contract created by this factory
    * @param _address Address of contract
    * @return boolean indicating whether the contract was created by this factory or not
    */
	function exists(address _address) external constant returns (bool) {
		return keccak256(DAOs[_address]) != keccak256("");
	}

	/*
    * @dev Receives info about address which sent DXC tokens to current contract and about amount of sent tokens from
    *       DXC token contract and then saves this information to DXCDeposit mapping
    * @param _from Address which sent DXC tokens
    * @param _amount Amount of tokens which were sent
    */
	function handleDXCPayment(address _from, uint _dxcAmount) external onlyDXC {
		require(_dxcAmount >= 10**18, "Amount of DXC for initial deposit must be equal or greater than 1 DXC");

		DXCDeposit[_from] += _dxcAmount;
	}

	/*
    * @dev Creates new CrowdsaleDAO contract, provides it with addresses of modules, transfers ownership to tx sender
    *      and saves address of created contract to DAOs mapping
    * @param _name Name of the DAO
    * @param _name Description for the DAO
    * @param _initialCapital initial capital for DAO that will be created
    */
	function createCrowdsaleDAO(string _name, string _description, uint _initialCapital) public correctInitialCapital(_initialCapital) enoughDXC(_initialCapital) {
		address dao = DAODeployer.deployCrowdsaleDAO(_name, _description, serviceContractAddress, votingFactory, serviceVotingFactory, DXC, _initialCapital);
		DXCDeposit[msg.sender] -= _initialCapital;
		TokenInterface(DXC).transfer(dao, _initialCapital);

		IDAOModules(dao).setStateModule(modules[0]);
		IDAOModules(dao).setPaymentModule(modules[1]);
		IDAOModules(dao).setVotingDecisionModule(modules[2]);
		IDAOModules(dao).setCrowdsaleModule(modules[3]);
		IDAOModules(dao).setProxyAPI(modules[4]);
		IDAOModules(dao).setApiSettersModule(modules[5]);
		DAODeployer.transferOwnership(dao, msg.sender);

		DAOs[dao] = _name;
		CrowdsaleDAOCreated(dao, _name);
	}

	modifier onlyDXC() {
		require(msg.sender == address(DXC), "Method can be called only from DXC contract");
		_;
	}

	modifier correctInitialCapital(uint value) {
		require(value >= 10**18, "Initial capital should be equal at least 1 DXC");
		_;
	}

	modifier enoughDXC(uint value) {
		require(value <= TokenInterface(DXC).balanceOf(this), "Not enough DXC tokens were transferred for such initial capital");
		require(DXCDeposit[msg.sender] >= value, "Not enough DXC were transferred by your address");
		_;
	}
}

contract DXC is MintableToken {
	address[] public additionalOwnersList; // List of addresses which are able to call `mint` function
	mapping(address => bool) public additionalOwners;  // Mapping of addresses which are able to call `mint` function
	uint public maximumSupply = 300000000 * 10**18; // Maximum supply of DXC tokens equals 300 millions

	event TokenCreation(address _address);
	event SetAdditionalOwners(address[] oldOwners, address[] newOwners);

	string public constant name = "Daox Coin";
	string public constant symbol = "DXC";
	uint public constant decimals = 18;

	/**
     * @dev Transfer specified amount of tokens to the specified address and call
     * standard `handleDXCPayment` method of Crowdsale DAO
     * @param _to The address of Crowdsale DAO
     * @param _amount The amount of tokens to send
    */
	function contributeTo(address _to, uint256 _amount) public {
		super.transfer(_to, _amount);
		require(_to.call(bytes4(keccak256("handleDXCPayment(address,uint256)")), msg.sender, _amount));
	}

	/**
     * @dev Overrides function to mint tokens from `MintableToken` contract with new modifier
     * @param _to The address that will receive the minted tokens.
     * @param _amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
    */
	function mint(address _to, uint256 _amount) isOwnerOrAdditionalOwner canMint maximumSupplyWasNotReached(_amount) public returns (bool) {
		totalSupply = totalSupply.add(_amount);
		balances[_to] = balances[_to].add(_amount);
		Mint(_to, _amount);
		Transfer(0x0, _to, _amount);
		return true;
	}

	/**
     * @dev Transfer specified amount of tokens to the specified list of addresses
     * @param _to The array of addresses that will receive tokens
     * @param _amount The array of uint values indicates how much tokens will receive corresponding address
     * @return True if all transfers were completed successfully
    */
	function transferTokens(address[] _to, uint256[] _amount) isOwnerOrAdditionalOwner public returns (bool) {
		require(_to.length == _amount.length);
		for (uint i = 0; i < _to.length; i++) {
			transfer(_to[i], _amount[i]);
		}

		return true;
	}

	/**
     * @dev Define array and mapping of addresses that will be additional owners
     * @param _owners The addresses that will be defined as additional owners
    */
	function setAdditionalOwners(address[] _owners) onlyOwner {
		SetAdditionalOwners(additionalOwnersList, _owners);

		for (uint i = 0; i < additionalOwnersList.length; i++) {
			additionalOwners[additionalOwnersList[i]] = false;
		}

		for (i = 0; i < _owners.length; i++) {
			additionalOwners[_owners[i]] = true;
		}

		additionalOwnersList = _owners;
	}

	/**
     * @dev Throws an exception if called not by owner or additional owner
     */
	modifier isOwnerOrAdditionalOwner() {
		require(msg.sender == owner || additionalOwners[msg.sender]);
		_;
	}

	/**
     * @dev Throws an exception if maximumSupply will be exceeded after minting
     * @param _amount The amount of tokens to mint
     */
	modifier maximumSupplyWasNotReached(uint256 _amount) {
		require(totalSupply.add(_amount) <= maximumSupply);
		_;
	}
}