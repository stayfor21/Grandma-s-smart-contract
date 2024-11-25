// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13 <0.9.0;

contract Granny {
    // Счетчик количества внуков
    uint8 public counter;

    // Сумма, внесенная бабушкой, которая может изменяться
    uint256 public bank;

    // Адрес бабушки (владельца контракта)
    address public owner;

    // Структура, представляющая внука
    struct Grandchild {
        string name;
        uint256 birthday;
        bool alreadyGotMoney;
        bool exists; 
    }

    // Массив адресов внуков для отслеживания
    address[] public arrGrandchilds;

    // Отображение для хранения данных о внуках
    mapping(address => Grandchild) public grandchilds;

    // Конструктор для инициализации контракта
    constructor() {
        owner = msg.sender;
        counter = 0;
    }

    // Пользовательский модификатор
    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner of the contract");
        _;
    }

    // Функция добавления внука в контракт
    function addGrandChild(address walletAddress, string memory name, uint256 birthday) public onlyOwner {
        require(birthday > 0, "Something is wrong with the day of birth!");
        require(grandchilds[walletAddress].exists == false, "There is already such grandchild!");

        // Добавляем данные о новом внуке
        grandchilds[walletAddress] = Grandchild(name, birthday, false, true);

        // Добавляем адрес в массив адресов внуков
        arrGrandchilds.push(walletAddress);
        counter++;

        emit NewGrandChild(walletAddress, name, birthday);
    }

    // Функция вывода средств
    function withdraw() public {
        address payable walletAddress = payable(msg.sender);

        require(
            grandchilds[walletAddress].exists == true,
            "There is no such grandchild!"
        );

        require(
            block.timestamp > grandchilds[walletAddress].birthday,
            "Birthday hasn't arrived yet"
        );

        require(
            grandchilds[walletAddress].alreadyGotMoney == false,
            "You have already received money"
        );

        uint256 amount = bank / counter;
        grandchilds[walletAddress].alreadyGotMoney = true;

        (bool success, ) = walletAddress.call{value: amount}("");
        require(success, "Transfer failed");

        emit GotMoney(walletAddress);
    }

    // Функция для получения части массива внуков
    function readGrandChildsArray(uint cursor, uint length) public view returns(address[] memory) {
        require(cursor < arrGrandchilds.length, "Cursor out of bounds");

        // Определяем фактическую длину возвращаемого массива, чтобы не выйти за границы
        uint actualLength = length;
        if (cursor + length > arrGrandchilds.length) {
            actualLength = arrGrandchilds.length - cursor;
        }

        address[] memory array = new address[](actualLength);
        for (uint i = 0; i < actualLength; i++) {
            array[i] = arrGrandchilds[cursor + i];
        }

        return array;
    }

    // Функция для проверки баланса
    function balanceOf() public view returns (uint256) {
        return address(this).balance;
    }

    // Функция для приема платежей eth
    receive() external payable { 
        bank += msg.value;
    }

    //событие
    event NewGrandChild(address indexed walletAddress, string name, uint256 birthday);
    event GotMoney(address indexed  walletAddress);
}
