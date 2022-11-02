#include maps\mp\_utility;
#include common_scripts\utility;

_error(msg)
{
    self tell(va("^1error: ^7%s", msg));
}

get_dvar_str_default(dvar, default_value)
{
    dvar_value = getdvar(dvar);
    return (dvar_value != "" ? dvar_value : default_value);
}

get_player_name(player)
{
    player_name = player.name;

    for(i = 0; i < player.name.size; i++)
    {
        if (player.name[i] == "]")
        {
            break;
        }
    }

    if (player.name.size != i)
    {
        player_name = getSubStr(player.name, i + 1, player.name.size);
    }

    return player_name;
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
    level.bank_allow_banking = getDvarIntDefault("bank_allow_banking", 1);              // disable/enable banking (on by default)
    level.bank_allow_paying = getDvarIntDefault("bank_allow_paying", 1);                // disable/enable paying to other players. (on by default)

    level.bank_preferred_prefix = get_dvar_str_default("bank_preferred_prefix", "/");   // the preferred prefix that must be at the beginning of the message ("/" by default)

    // create bank folders/files
    level.bank_folder = va("%s/bank", getdvar("fs_homepath"));
    if (!directoryExists(level.bank_folder))
        createDirectory(level.bank_folder);

    // add callback to player chat
    onPlayerSay(::player_say);
}

is_prefix(str)
{
    return (getsubstr(str, 0, level.bank_preferred_prefix.size) == level.bank_preferred_prefix);
}

player_say(message, mode)
{
    message = toLower(message);

    if (is_prefix(message))
    {
        // disallow commands after game ends
        if (is_true(level.intermission))
        {
            self _error("you cannot use the bank after the game has ended.");
            return false;
        }

        args = strtok(message, " ");
        command = getsubstr(args[0], 0, level.bank_preferred_prefix.size);

        switch (command)
        {
        case "deposit":
        case "d":
        {
            if (is_false(level.bank_allow_banking))
            {
                self tell("banking is not enabled on this server.");
                return false;
            }
            self thread deposit(args);
            return false;
        }
        case "withdraw":
        case "w":
        {
            if (is_false(level.bank_allow_banking))
            {
                self tell("banking is not enabled on this server.");
                return false;
            }
            self thread withdraw(args);
            return false;
        }
        case "balance":
        case "b":
        case "money":
        {
            if (is_false(level.bank_allow_banking))
            {
                self tell("banking is not enabled on this server.");
                return false;
            }
            self thread balance();
            return false;
        }
        case "pay":
        case "p":
        {
            if (is_false(level.bank_allow_paying))
            {
                self tell("paying is not enabled on this server.");
                return false;
            }
            self thread pay(args);
            return false;
        }
        }
    }

    return true;
}

deposit(args)
{
    if (args.size < 1)
    {
        self _error("usage: ^1/deposit ^7<amount|all>");
        return;
    }

    deposit = args[1];

    if (deposit == "all")
    {
        deposit_internal(self.score);
        return;
    }

    deposit = int(deposit);

    if (int64_op(deposit, "<=", 0))
    {
        self _error("you cannot deposit invalid amounts of money.");
        return;
    }

    if (int64_op(deposit, ">", self.score))
    {
        self _error("you cannot deposit more money than you have.");
        return;
    }

    deposit_internal(deposit);
}

deposit_internal(money)
{
    self bank_add(money);
    self.score -= money;
    self tell(va("you deposited ^2$%s^7 into the bank, you have ^2$%s ^7remaining.", money, self bank_read()));
}

withdraw(args)
{
    if (args.size < 1)
    {
        self _error("usage: ^1/withdraw ^7<amount|all>");
        return;
    }

    withdraw = args[1];

    if (withdraw == "all")
    {
        withdraw = self bank_read();
    }

    withdraw = int(withdraw);

    if (int64_op(withdraw, "<=", 0))
    {
        self _error("you cannot withdraw invalid amounts of money.");
        return;
    }

    new_score = int64_op(self.score, "+", withdraw);
    if (int64_op(new_score, ">", 1'000'000))
    {
        value = 1'000'000 - self.score;
        if (value == 0)
        {
            self _error("you already have maximum points!");
        }

        withdraw_internal(value);
    }
    else
    {
        withdraw_internal(withdraw);
    }
}

withdraw_internal(money)
{
    current = self bank_read();
    if (int64_op(current, "<", money))
    {
        self _error("you cannot withdraw more money than you have.");
        return;
    }

    self bank_sub(money);
    current = self bank_read();
    self tell(va("you withdrew ^2$%s ^7from the bank. (^2$%s ^7remaining)", money, current));

    if (int64_op(current, "==", 0))
    {
        self bank_remove();
    }

    self.score += money;
}

pay(args)
{
    if (args.size < 2)
    {
        self _error("usage: ^1/pay ^7<player> <amount>");
        return;
    }

    target_name = args[1];

    foreach (p in level.players)
    {
        player_name = tolower(get_player_name(p));
        if (issubstr(player_name, target_name))
            player = p;
    }

    if (!isdefined(player))
    {
        self _error(va("could not find player with name ^1%s^7", target_name));
        return;
    }

    amount = int(args[2]);

    if (int64_op(amount, "<=", 0))
    {
        self _error("you cannot pay invalid amounts of money.");
        return;
    }

    if (int64_op(amount, ">", self.score))
    {
        self _error("you cannot pay more money than you have.");
        return;
    }

    self.score -= amount;
    player.score += amount;

    self tell(va("you paid ^2$%s ^7to %s", amount, player.name));
    player tell(va("%s ^7paid you ^2$%s^7!", self.name, amount));
}

balance()
{
    value = self bank_read();
    self tell(va("you have ^2$%s ^7in your bank account.", value));
}
