/*
 * 智能合约 第三课
 * 宁达非
 *
 */

pragma solidity ^0.4.18;

import './SafeMath.sol';

contract Payroll {
    
    using SafeMath for uint256;
    
    struct Employee {
        address id;
        uint salary;
        uint lastPayday;
    }

    uint constant                   payDuration = 10 seconds;
    address                         owner;
    uint                            totalsalary = 0;
    mapping(address => Employee)    public employees;
    
    function Payroll() {
        owner = msg.sender;
    }
    
    /////////////////////////////////////////////////////////////////
    /////////////////////////// Modifier ////////////////////////////
    /////////////////////////////////////////////////////////////////

    modifier onlyOwner{
        require(msg.sender == owner);
        _;
    }
    
    modifier employeeExist(address emplid){
        var checkempl =employees[emplid];
        assert(checkempl.id != 0x0);
        _;
    }
    
    modifier idNotExist(address emplid){
        var checkempl =employees[emplid];
        assert(checkempl.id == 0x0);
        _;
    }
    
    /////////////////////////////////////////////////////////////////
    /////////////////////////// Functions ///////////////////////////
    /////////////////////////////////////////////////////////////////
    
    function _partialPaid(Employee empl) private{
        uint payment = empl.salary.mul((now.sub(empl.lastPayday)).div(payDuration));
        assert(_hasEnoughToPayPersonally(empl));
        empl.id.transfer(payment);
    }
    
    function addFund() payable returns (uint) {
        return this.balance;
    }

    function calculateRunway() returns (uint) {
        return this.balance.div(totalsalary);
    }

    function hasEnoughFund() returns (bool) {
        return calculateRunway() >= 1;
    }
    
    function _hasEnoughToPayPersonally(Employee empl) private returns(bool){
        return this.balance.div(empl.salary) > 0;
    }
    
    function addEmployee(address emplid, uint sal) onlyOwner idNotExist(emplid) {
        var checkempl = employees[emplid];
        totalsalary = totalsalary.add(sal * 1 ether);
        employees[emplid] = Employee(emplid, sal * 1 ether, now);
    }
    
    function removeEmployee(address emplid) onlyOwner employeeExist(emplid) {
        var checkempl =employees[emplid];
        _partialPaid(employees[emplid]);
        totalsalary = totalsalary.sub(employees[emplid].salary);
        delete employees[emplid];
    }

    function getPaid() employeeExist(msg.sender) {
        var checkempl =employees[msg.sender];
        
        uint nextPayday = checkempl.lastPayday + payDuration;
        if (nextPayday > now){revert();}
        assert(_hasEnoughToPayPersonally(checkempl));
        employees[msg.sender].lastPayday = nextPayday;
        employees[msg.sender].id.transfer(employees[msg.sender].salary);
    }

    function updateEmployee(address emplid, uint Sal) onlyOwner employeeExist(emplid) {
        var checkempl = employees[emplid];
        _partialPaid(employees[emplid]);
        totalsalary = totalsalary.sub(employees[emplid].salary);
        totalsalary = totalsalary.add(Sal * 1 ether);
        employees[emplid].salary = Sal * 1 ether;
        employees[emplid].lastPayday = now;
        return;
    }
    
    function checkEmployee(address emplid) returns (uint salary, uint lastPayday){
        var employee = employees[emplid];
        salary = employee.salary;
        lastPayday = employee.lastPayday;
    }
    
    /////////////////////////////////////////////////////////////////
    ///////////// 第三节课增加函数changePaymentAddress //////////////
    /////////////////////////////////////////////////////////////////
    
    function changePaymentAddress (address newEmplid) employeeExist(msg.sender) idNotExist (newEmplid){
        //该函数的要求应该是: 只有员工并且本人才可以改地址
        //                    员工所改地址必须是不存在的地址
        //                    员工除了改地址以外，其他不改变（包括salary和lastPay的时间）
        //                    不可以在员工改地址钱结账，因为提供的情景是员工原地址可能被黑
        // 实际情况分两种：1）公司注册 employee ID 必须不变，无论钱包地址是否改变
        //                 2）公司注册 employee ID 与 员工钱包地址一致
        //
        
        /* 1) 公司注册 employee ID 必须不变，无论钱包地址是否改变 */
        
        var checkempl = employees[msg.sender];
        employees[msg.sender].id = newEmplid;
        
        /* 2) 公司注册 employee ID 与 员工钱包地址一致             */
        
    //  uint temSalary = employees[msg.sender].salary;
    //  uint temPayTime = employees[msg.sender].lastPayday;
        
    //  employees[newEmplid] = Employee(newEmplid, temSalary, temPayTime);
    //  delete employees[msg.sender];
        
    }
    
    
}









