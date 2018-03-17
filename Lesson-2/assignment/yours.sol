/*
 * 第二课作业
 * by 65-宁达非
 *
 * 这个文档包括：
 *
 * 1. 智能合约代码
 * 2. gas的变化记录
 * 3. 如何优化calculateRunway这个函数
 *
 */



////////////////////////////////////////////////////////////////////////////////
///////////////////////////// 1. 智能合约代码 ////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

pragma solidity ^0.4.14;

contract Payroll {

    struct Employee {
        address id;
        uint salary;
        uint lastPayday;
    }

    uint constant payDuration = 10 seconds;
    address       owner;
    Employee[]    employees;
    event         log(string);

    function Payroll() {
        owner = msg.sender;
    }

    function _partialPaid(Employee empl) private{
        if(hasEnoughFund()){
            uint payment = empl.salary * (now - empl.lastPayday) / payDuration;
            empl.id.transfer(payment);
        }else{ revert();} //之前觉得不用require是为了省gas
    }

    function _findEmployee(address emplid) private returns (Employee, uint){
        for(uint i = 0; i < employees.length; i++){
            // if address exists, return info binding the address
            if(employees[i].id == emplid){
                return (employees[i], i);
            }
            // if it doesnt exist, it will return (0x0, 0, 0)
        }
    }

    function addEmployee(address emplid, uint sal){
        require(msg.sender == owner);
        //to replace: Employee checkempl = _findEmployee(emplid)：
        var(checkempl, index) = _findEmployee(emplid);
        // I dont know why example code use assert(). I think using require() is ok.
        require(checkempl.id == 0x0);

        employees.push(Employee(emplid,sal * 1 ether,now));
    }


    function removeEmployee(address emplid){
        require(msg.sender == owner);
        var(checkempl, index) = _findEmployee(emplid);

        // I dont know why example code use assert(). I think using require() is ok.
        require(checkempl.id != 0x0);

        _partialPaid(employees[index]);
        delete employees[index];
        employees[index] = employees[employees.length -1];
        employees.length -= 1;
        return;
    }


    function addFund() payable returns (uint) {
        return this.balance;
    }

    function calculateRunway() returns (uint) {
        uint totalsalary = 0;
        for(uint i = 0; i< employees.length; i++){
            totalsalary += employees[i].salary;
        }
        return this.balance / totalsalary;
    }

    function hasEnoughFund() returns (bool) {
        return calculateRunway() >= 1;
    }

    function getPaid() {
        var(checkempl, index) = _findEmployee(msg.sender);
        require(checkempl.id != 0x0);
        // I dont know why example code use assert. I think using require() is ok.
        uint nextPayday = checkempl.lastPayday + payDuration;

        if (nextPayday > now){revert();}

        require(hasEnoughFund());
        //个人认为，应该取employees[index] 这个数组里面的值进行操作
        //用var创建checkempl的进行操作并没有改变实际数组里的target项
        //视频中强行把memory换成storage虽然有正确的地址制约，但并是不好习惯
        employees[index].lastPayday = nextPayday;
        employees[index].id.transfer(employees[index].salary);
    }

    function updateEmployee(address emplid, uint Sal) {
        require(msg.sender == owner);

        var(checkempl, index) = _findEmployee(emplid);

        // I dont know why example code use assert. I think using require() is ok.
        require(checkempl.id != 0x0);
        //个人认为，应该取employees[index] 这个数组里面的值进行操作
        //用var创建checkempl的进行操作并没有改变实际数组里的target项
        //视频中强行把memory换成storage虽然有正确的地址制约，但并是不好习惯
        _partialPaid(employees[index]);
        employees[index].salary = Sal * 1 ether;
        employees[index].lastPayday = now;
        log("Employee info updated successfully");
        return;
    }
}




////////////////////////////////////////////////////////////////////////////////
///////////////////////////// 2. gas变化记录 ////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


// Employee    Transaction    Execution     Difference
// ---------------------------------------------------
// 01          22979          1707          N/A
// 02          23743          2471          764
// 03          24507          3235          764
// 04          25271          3999          764
// 05          26035          4763          764
// 06          26799          5527          764
// 07          27563          6291          764
// 08          28327          7055          764
// 09          29091          7819          764
// 10          29855          8583          764


// 在每添加一个新的employee以后calculateRunway都会比上一次多消耗 764 gas
// 原因：
// 因为在原calculateRunway函数中，for loop所loop的employees数组每次都会
// 比上一次多一个数组内的项，几多一个“Employee”，因此该for loop每多扫一个项，
// 就会多消耗764 gas。




////////////////////////////////////////////////////////////////////////////////
/////////////////////// 3. 如何优化calculateRunway这个函数 ////////////////////////
////////////////////////////////////////////////////////////////////////////////


// 解决方法是尽量不要用到 for loop：
// 可以设置一个 global variable “Totalsalary”，
// 在每一次添加新的employee或者update一个employee的时候，
// 对这个Total salary 进行改变。
// 具体修改 addEmployee, updateEmployee 和 removeEmployee 三个functions：


uint Totalsalary = 0;

function addEmployee(address emplid, uint sal){
    require(msg.sender == owner);
    var(checkempl, index) = _findEmployee(emplid);
    require(checkempl.id == 0x0);
    employees.push(Employee(emplid,sal * 1 ether,now));

    // 添加:
    Totalsalary += sal * 1 ether;
}

function updateEmployee(address emplid, uint Sal) {
    require(msg.sender == owner);
    var(checkempl, index) = _findEmployee(emplid);
    require(checkempl.id != 0x0);
    _partialPaid(employees[index]);

    //添加：
    Totalsalary -= employees[index].salary；
    Totalsalary += Sal * 1 ether;

    employees[index].salary = Sal * 1 ether;
    employees[index].lastPayday = now;
    log("Employee info updated successfully");
    return;
}

function removeEmployee(address emplid){
    require(msg.sender == owner);
    var(checkempl, index) = _findEmployee(emplid);
    require(checkempl.id != 0x0);
    _partialPaid(employees[index]);

    //添加：
    Totalsalary -= employees[index].salary；

    delete employees[index];
    employees[index] = employees[employees.length -1];
    employees.length -= 1;
    return;
}

// 最后删掉calculateRunway 的 for loop：

function calculateRunway() returns (uint) {
    return this.balance / totalsalary;
}
