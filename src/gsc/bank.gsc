#include maps\mp\_utility;
#include common_scripts\utility;

// printing utils and such
_bank_log(msg)
{
    if (level._bank_debug)
        printf(va("^2[BANK]: ^7%s", msg));
}

_error(msg)
{
    self tell(va("^1ERROR: ^7%s", msg));
}

// main stuff below
init()
{
    // configurable dvars
    level._bank_debug = getDvarIntDefault("bank_debug", 0);

    // create bank folders/files
    bank_folder = va("%s/bank", getdvar("fs_homepath"));
    if (!directoryexists(bank_folder))
    {
        _bank_log("Creating bank directory...");
        createdirectory(bank_folder);
    }

    bank_file = va("%s/bank.json", bank_folder);
    if (!fileexists(bank_file))
    {
        _bank_log("Creating bank JSON file...");

        // placeholder value, should remain if you don't wanna mess shit up
        // im too lazy to do it any other way as of now
        bank = [];
        bank["0"] = 0;

        writefile(bank_file, jsonserialize(bank));
    }

    level.bank = bank_file;
    _bank_log(va("level.bank = %s", level.bank));

    // add callback to player chat
    onPlayerSay(::player_say);
}

player_say(message, mode)
{
    if (message[0] == "/")
    {
        args = strtok(message, " ");
        command = args[0];

        switch (command)
        {
        case "/deposit":
        case "/d":
            self thread deposit(args);
            break;

        case "/withdraw":
        case "/w":
            self thread withdraw(args);
            break;

        case "/balance":
        case "/b":
        case "/money":
            self thread balance();
            break;
        }

        return false;
    }

    return true;
}

deposit(args)
{
    if (!isdefined(args[1]))
    {
        self _error("You must provide a amount to deposit");
        return;
    }

    deposit = args[1]; // string
    deposit_int = int(deposit); // int

    // "all" amount
    if (typeof(deposit) == "string"
            && deposit == "all")
    {
        deposit_internal(self.score);
        return;
    }

    if (deposit_int < 0 || deposit_int == 0 || (self.score - deposit_int) < 0)
    {
        self _error("You cannot deposit invalid amounts of money");
        return;
    }
    else if (deposit_int > self.score)
    {
        self _error("You cannot deposit more money than you have");
        return;
    }

    deposit_internal(deposit_int);
}

deposit_internal(money)
{
    guid = va("%s", self getguid()); // getguid() returns int but this will make it string
    bank = jsonparse(readfile(level.bank));
    if (!isdefined(bank[guid]))
    {
        _bank_log(va("Creating new bank entry for %s", guid));
        bank[guid] = 0;
    }

    old = bank[guid];
    bank[guid] = int((old + money));
    self.score -= money;

    self tell(va("You have deposited ^2$%s ^7into the bank", money));

    writefile(level.bank, jsonserialize(bank));
}

withdraw(args)
{
    if (!isdefined(args[1]))
    {
        self _error("You must provide a amount to withdraw");
        return;
    }

    withdraw = args[1]; // string
    withdraw_int = int(withdraw); // int

    // "all" amount
    if (typeof(withdraw) == "string"
            && withdraw == "all")
    {
        withdraw_internal();
        return;
    }

    if (withdraw_int < 0 || withdraw_int == 0)
    {
        self _error("You cannot withdraw invalid amounts of money");
        return;
    }

    withdraw_internal(withdraw_int);
}

withdraw_internal(money)
{
    guid = va("%s", self getguid());
    bank = jsonparse(readfile(level.bank));
    if (!isdefined(bank[guid]))
    {
        self _error("You do not have a bank account with money");
        return;
    }

    _bank_log(money);
    _bank_log(bank[guid]);
    if (money > bank[guid])
    {
        self _error("You cannot withdraw more money than you have");
        return;
    }

    // if money isn't defined, let's assume it's all the money they wanna withdraw
    if (!isdefined(money))
    {
        money = bank[guid];
    }

    // subtract old money - withdraw
    old = bank[guid];
    bank[guid] = int((old - money));
    self.score += money;

    self tell(va("You have withdrew ^2$%s ^7from the bank, you have ^2$%s ^7remaining", money, bank[guid]));

    if (bank[guid] == 0)
    {
        arrayremovekey(bank, guid);
        _bank_log(va("Deleting bank entry for %s", guid));
    }

    writefile(level.bank, jsonserialize(bank));
}

balance()
{
    bank = jsonparse(readfile(level.bank));
    guid = va("%s", self getguid());
    if (!isdefined(bank[guid]))
    {
        self _error("You do not have a bank account with money");
        return;
    }

    self tell(va("You have ^2$%s ^7in your bank account", bank[guid]));
}
