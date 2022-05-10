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

    deposit = int(args[1]);
    if ((self.score - deposit) < 0 && deposit != 0)
    {
        self _error("You cannot deposit non-positive amounts of money");
        return;
    }
    if (deposit > self.score)
    {
        self _error("You cannot deposit more money than you have");
        return;
    }

    guid = va("%s", self getguid()); // getguid() returns int but this will make it string
    bank = jsonparse(readfile(level.bank));
    if (!isdefined(bank[guid]))
    {
        _bank_log(va("Creating new bank entry for %s", guid));
        bank[guid] = 0;
    }

    // add old money + deposit
    old = bank[guid];
    bank[guid] = int((old + deposit));
    self.score -= deposit;

    self tell(va("You have deposited ^2$%s ^7into the bank", deposit));

    writefile(level.bank, jsonserialize(bank));
}

withdraw(args)
{
    if (!isdefined(args[1]))
    {
        self _error("You must provide a amount to withdraw");
        return;
    }

    withdraw = int(args[1]);
    if (withdraw < 0)
    {
        self _error("You cannot withdraw negative amounts of money");
        return;
    }

    guid = va("%s", self getguid());
    bank = jsonparse(readfile(level.bank));
    if (!isdefined(bank[guid]))
    {
        self _error("You do not have a bank account with money");
        return;
    }
    if (withdraw > bank[guid])
    {
        self _error("You cannot withdraw more money than you have (/balance)");
        return;
    }

    // subtract old money - withdraw
    old = bank[guid];
    bank[guid] = int((old - withdraw));
    self.score += withdraw;

    self tell(va("You have withdrew ^2$%s ^7into the bank", withdraw));

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
