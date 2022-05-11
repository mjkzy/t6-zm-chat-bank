# T6ZM Chat Bank
a simple chat bank system

## requisites
[t6-gsc-utils](https://github.com/fedddddd/t6-gsc-utils/releases)

## commands
<b>/deposit %amount%</b> (/d) - deposit money to bank account</br>
<b>/withdraw %amount%</b> (/w) - withdraw money from bank account</br>
<b>/balance</b> (/b, /money) - shows balance in bank account</br>

## possible issues
using this on multiple servers could lead to unexpected/bad behavior. for this reason, this isn't ideal in the current state. this is because multiple processes could access the file and wouldn't be able to write.
