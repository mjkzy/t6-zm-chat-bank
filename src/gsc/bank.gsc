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

get_bank_filename()
{
    guid = self getGuid();
    return level.bank_folder + "/" + guid;
}

bank_write(value)
{
    name = self get_bank_filename();
    writeFile(name, value);
}

bank_read()
{
    name = self get_bank_filename();
    if (!fileExists(name))
    {
        return 0;
    }
    return int64_op(readFile(name), "+", 0);
}

bank_add(value)
{
    current = self bank_read();
    self bank_write(int64_op(current, "+", value));
}

bank_sub(value)
{
    current = self bank_read();
    self bank_write(int64_op(current, "-", value));
}

bank_remove()
{
    name = self get_bank_filename();
    removeFile(name);
}

// main stuff below
init()
{
    // configurable dvars
    level._bank_debug = getDvarIntDefault("bank_debug", 0);

    // create bank folders/files
    level.bank_folder = va("%s/bank", getdvar("fs_homepath"));
    if (!directoryExists(level.bank_folder))
    {
        _bank_log("Creating bank directory...");
        createDirectory(level.bank_folder);
    }

    // add callback to player chat
    onPlayerSay(::player_say);
}

player_say(message, mode)
{
    message = toLower(message);

    if (message[0] == "/" || message[0] == "!")
    {
        // disallow commands after game ends
        if (level.intermission)
        {
            self _error("You cannot use the bank after the game has ended.");
            return false;
        }

        args = strtok(message, " ");
        command = getSubStr(args[0], 1);

        switch (command)
        {
        case "deposit":
        case "d":
        {
            self thread deposit(args);
            return false;
        }
        case "withdraw":
        case "w":
        {
            self thread withdraw(args);
            return false;
        }
        case "balance":
        case "b":
        case "money":
        {
            self thread balance();
            return false;
        }
        }
    }

    return true;
}

deposit(args)
{
    if (!isdefined(args[1]))
    {
        self _error("You must provide an amount to deposit.");
        return;
    }

    deposit = args[1];

    if (deposit == "all")
    {
        deposit_internal(self.score);
        return;
    }

    if (int64_op(deposit, "<=", 0))
    {
        self _error("You cannot deposit invalid amounts of money.");
        return;
    }

    if (int64_op(deposit, ">", self.score))
    {
        self _error("You cannot deposit more money than you have.");
        return;
    }

    deposit_internal(int(deposit));
}

deposit_internal(money)
{
    self bank_add(money);
    self.score -= money;
    self tell(va("You have deposited ^2$%s^7 into the bank, you have ^2$%s ^7remaining.", money, self bank_read()));
}

withdraw(args)
{
    if (!isdefined(args[1]))
    {
        self _error("You must provide an amount to withdraw.");
        return;
    }

    withdraw = args[1];

    if (withdraw == "all")
    {
        withdraw = self bank_read();
    }

    if (int64_op(withdraw, "<=", 0))
    {
        self _error("You cannot withdraw invalid amounts of money.");
        return;
    }

    new_score = int64_op(self.score, "+", withdraw);
    if (int64_op(new_score, ">", 1'000'000))
    {
        value = 1'000'000 - self.score;
        if (value == 0)
        {
            self _error("You already have maximum points!");
        }

        withdraw_internal(value);
    }
    else
    {
        withdraw_internal(int(withdraw));
    }
}

withdraw_internal(money)
{
    current = self bank_read();
    if (int64_op(current, "<", money))
    {
        self _error("You cannot withdraw more money than you have.");
        return;
    }

    self bank_sub(money);
    current = self bank_read();
    self tell(va("You have withdrawn ^2$%s ^7from the bank, you have ^2$%s ^7remaining.", money, current));

    if (int64_op(current, "==", 0))
    {
        self bank_remove();
    }

    self.score += money;
}

balance()
{
    value = self bank_read();
    self tell(va("You have ^2$%s ^7in your bank account.", value));
}
