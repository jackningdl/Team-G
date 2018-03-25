/*
 * 智能合约 第四课作业
 * 宁达非
 *
 */


pragma solidity ^0.4.4;

import './SafeMath.sol';
import './Ownable.sol';

contract Payroll is Ownable {

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


    /////////////////////////////////////////////////////////////////
    /////////////////////////// Modifier ////////////////////////////
    /////////////////////////////////////////////////////////////////

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

    function addFund() payable public returns (uint) {
        return this.balance;
    }

    function calculateRunway() public view returns (uint) {
        return this.balance.div(totalsalary);
    }

    function hasEnoughFund() public view returns (bool) {
        return calculateRunway() >= 1;
    }

    function _hasEnoughToPayPersonally(Employee empl) private view returns(bool){
        return this.balance.div(empl.salary) > 0;
    }

    function addEmployee(address emplid, uint sal) onlyOwner idNotExist(emplid) public {
        var checkempl = employees[emplid];
        totalsalary = totalsalary.add(sal * 1 ether);
        employees[emplid] = Employee(emplid, sal * 1 ether, now);
    }

    function removeEmployee(address emplid) onlyOwner employeeExist(emplid) public {
        var checkempl =employees[emplid];
        _partialPaid(employees[emplid]);
        totalsalary = totalsalary.sub(employees[emplid].salary);
        delete employees[emplid];
    }

    function getPaid() employeeExist(msg.sender) public{
        var checkempl =employees[msg.sender];
        uint nextPayday = checkempl.lastPayday + payDuration;
        if (nextPayday > now){revert();}
        assert(_hasEnoughToPayPersonally(checkempl));
        employees[msg.sender].lastPayday = nextPayday;
        employees[msg.sender].id.transfer(employees[msg.sender].salary);
    }

    function updateEmployee(address emplid, uint Sal) onlyOwner employeeExist(emplid) public {
        var checkempl = employees[emplid];
        _partialPaid(employees[emplid]);
        totalsalary = totalsalary.sub(employees[emplid].salary);
        totalsalary = totalsalary.add(Sal * 1 ether);
        employees[emplid].salary = Sal * 1 ether;
        employees[emplid].lastPayday = now;
        return;
    }

    function checkEmployee(address emplid) public view returns (uint salary, uint lastPayday) {
        var employee = employees[emplid];
        salary = employee.salary;
        lastPayday = employee.lastPayday;
    }

    function changePaymentAddress (address newEmplid) employeeExist(msg.sender) idNotExist (newEmplid) public {
        var checkempl = employees[msg.sender];
        employees[msg.sender].id = newEmplid;
    }

}


