# Auto SSH

This [expect](https://en.wikipedia.org/wiki/Expect) script allows to auto __ssh__ into a server providing just an alias for that connection. 
It automatically fills the password for that connection, asking instead the __master password__ of where all the _passwords_ are stored. 
They are stored in an encrypted file, so that, obtaining any of them, requires to decrypt it via a _master password_. Remembering a single _password_ without bothering to remember every single connection's _password_ is  one aim of this auto-ssh. For not critical connections, the script accepts an alternative ways to provide the _master password_ having it stored in an ENV variable for full automatic login.

## requisites

* [expect](https://en.wikipedia.org/wiki/Expect)
* unix `shell` ( `bash/csh/zsh/` ...)
* `openssl`   (Being ssh built on top of openssl there should be no issue for this)

## limitations

* It requires `openssl` which could be not available for _SSH_ version not built on top of it.

* There is no way, currently, to have more than 1 _passwords-file_ (and so different _master passwords_ for each).

* being an [expect](https://en.wikipedia.org/wiki/Expect) script, the script's flags (ex __-d__
and __-c__ or __-h__) are parsed still by _expect_ itself and not forwarded to be parsed separately. They then need to be preceeded by the usual end-of-options sequence: "--"
This means that instead of just `auto_ssh.tcl -d clear.txt -env` I must type `auto_ssh.tcl -- -d clear.txt -env`

## installation

1. git clone somewhere (ex from your home directory, so that it will create the sub directory _auto_ssh_ within everything included)

2. make sure it is accessible:
     * adding its containing dir in `$PATH` (`PATH="${PATH}:${HOME}/auto_ssh"`)
     * or aliasing it `alias as="${HOME}/auto_ssh/auto_ssh.tcl"`

3. likely you need to set exec permissions `chmd +x ${HOME}/auto_ssh/auto_ssh.tcl`

### useful extra settings
It could be useful for common usages, to define a tiny shell function
``` shell
function as {
    local as_dir=${HOME}/auto_ssh
    if [[ -z $1  ]]
    then
        ${as_dir}/auto_ssh.sh
    elif [[ $1 == "k" ]]
    then
        vi ${as_dir}/known_hosts
    elif [[ $1 == "t" ]] # run the tcl script (forwarding any args)
    then
        ${as_dir}/auto_ssh.tcl -- "${@:2}"
    elif [[ $1 == "x" ]] # extract the password for the specified key
    then
        ${as_dir}/auto_ssh.tcl -- -env -x $2
    else
        cd ${as_dir}
    fi
}
```
so that it's possible to do the following:
* `as` to trigger the shell menu
* `as k` to edit the `known_hosts` file
* `as t` to launch the bare tcl script
* `as x` to extract a given password from the password file

You can put that function in your `~/.bashrc`, in your `~/.zshrc` or even better in a `~/_shell.functions.sh` which you can source from all your shell resource files, so that it will work in any shell.

## usages

### create the known_hosts

First of all you should have a proper [known-hosts](https://github.com/sbasile-ch/auto_ssh/blob/master/known_hosts). The automatic ssh will be possible only against any of the connections listed in there.
A connection is a line in known-hosts. A line of 7 (comma separated) fields. Like the following:
```shell
        live, chicweb, 7, , chicbeplive, chicweb7v.orctel.internal,    alias45
```
the meaning of the 7 fields is:
* category (mandatory) (ex `live`). It represents the 1st level to categorize a connection
* nick1 (optional) (ex `chicweb`) a nick to narrow down the connections in that `category` if they are more than 1 (likely)
* nick2 (optional) (ex `7`)a nick to furtherly narrow down if it's required inside  `nick1` 
* nick3 (optional) hardly used, but just in case you want to narrow down inside `nick2` 
* user  (mandatory) (ex `chicbeplive`) the user for your: ssh `user`@address
* server address (mandatory)  (ex `chicweb7v.orctel.internal`) the user for your: ssh user@`address` 
* pass-key (mandatory) (`alias45`) the key to identify the password. This pass-key will be used to look up for its pass-value in the encrypted `${HOME}/auto_ssh/psw.enc`
the `pass-key` value can be of these types
    - `xxxxx`  a string to look-up for a password
    - `2fa:`   to identify that the ssh requires dual factor authentication. Not much you can automate in this case. Tagging a `2fa:` will at least give you quickly a ssh command to run once typed in the 2fa from your phone.
    - `i:xxxxx` where "xxxxx" is a string used to look-up (in the usual `${HOME}/auto_ssh/psw.enc`) for a file-pathname (ex /Users/sbasile/.ssh/rob-aws-live.pem) which is the `image` to be used in a `ssh -i`
    
ex. (note using the function as specified in [useful extra settings](#useful-extra-settings)
```shell
grep -w live know_hosts | grep -w chicweb | grep -w 7
live, chicweb, 7, , chicbeplive, chicweb7v.orctel.internal,    i:alias45

as x i:alias45    
look up with pass-key: [i:alias45]
/Users/sbasile/.ssh/rob-aws-live.pem
```    


### create a passwords-file

Once you have created the list of ssh connections in `known-hosts` you want to encrypt their passwords in `${HOME}/auto_ssh/psw.enc`. You will temporarily create a clear _text_ file, containing the desired passwords (ex. [passwords.txt](https://github.com/sbasile-ch/auto_ssh/blob/master/passwords.txt) ). The structure of this file is just a list of lines (1 for each password). Every line is like this:
```shell
        alias   ,password
```
thus, 2 tokens separated by blanks (spaces or tabs) and 1 comma `,`. 

The __first__ token (`alias`) is the pass-key used in [known-hosts](https://github.com/sbasile-ch/auto_ssh/blob/master/known_hosts). 

The __second__ token is the password in clear text.

__NOTE THAT THE PASSWORD IS ANYTHING AFTER THE COMMA.__ This allows to have any kind of password (spaces included). So __be careful__ if you leave any spaces at the end of a password, because they will be taken __as part of it__.
Anyhow a warning will be issued when compiling you clear `passwords.txt`, if spaces or tab are found after the comma.

Once the text file has been completed, you need to encrypt it:
```shell
auto_ssh.tcl -- -c passwords.txt
```
Providing a master-password at this stage, will encrypt the clear text file into a `psw.enc` in the directory where `auto_ssh.tcl` is installed (ex. `${HOME}/auto_ssh/psw.enc`)

It's always better to remove the clear text file and to leave nothing not encrypted.

### show the passwords-file

To dump clearly the content of the encrypted passwords-file, run:

```shell
auto_ssh.tcl -- -d passwords.txt
```

This will prompt for the _master password_ and, if it is correct, it will decrypt the content into the clear text file _passwords.txt_. This can be useful for changing the current password-file, in a sequence of decrypt_into_temp_file/edit_temp_file/re-encrypt_from_temp_file/delete_temp_file.


### ssh directly into a connection

For any configured connection in [known-hosts](https://github.com/sbasile-ch/auto_ssh/blob/master/known_hosts), and password in `psw.enc`, it is then possible to auto **ssh** to that `username@server` providing the nick of the connection and the _master password_.
ex.
fot the following connection in [known-hosts](https://github.com/sbasile-ch/auto_ssh/blob/master/known_hosts)
```shell
        chic, b, 7, , chicbeplive, chicweb1v.orctel.internal,    alias45
```
and following entry encrypted in _psw.enc_   (with for example a _master password_ __abc__)
```shell
            alias45    ,pass123xxx
```

it is possible to _ssh_ directly as
```shell
auto_ssh.tcl chic b 7
```

and typing password __abc__, instead of typing

```shell
ssh chicbeplive@chicweb1v.orctel.internal
```

and password __pass123xxx__


### ssh with no master-password typed

It's possible to `ssh` into a server with no password typed at all, providing the flag `-env`

```shell
auto_ssh.tcl -- -env chic b 7       #note the '--' as explained in the limitations
```
What the `-env` flag does, is to read the _master-password_ from the `ENV` variable whose name is the value of `CONFIG_MP` in [config](https://github.com/sbasile-ch/auto_ssh/blob/1f894d89025eb40f4e42917e5d5b5b290ba9a105/config#L6) 
So if the _config_ has this entry
```shell
set CONFIG_MP       "AUTO_SSH_CONFIG_MP"      
```
the _master-password_ will be the value of `$AUTO_SSH_CONFIG_MP`
Actually to have it not in clear text (which could just be shown with an `env` command), there is a tiny intermidiate step of encryption/decryption of that value.
The encryption key used is the value of `CONFIG_MP_KEY` in the [config](https://github.com/sbasile-ch/auto_ssh/blob/1f894d89025eb40f4e42917e5d5b5b290ba9a105/config#L5) file
The 2 steps to use the `-env` flag would then be:

```shell
# 1. - define an encrypted value for the master password
auto_ssh.tcl -- -str   # suppose it returns [U2FsdGVkX19en7cv1Mv/0E1xaFgM4lvLt1Hg+o69Le8=]

# 2. - assign that value to the variable named in CONFIG_MP 
export AUTO_SSH_CONFIG_MP=U2FsdGVkX19en7cv1Mv/0E1xaFgM4lvLt1Hg+o69Le8=
```

Of course it's still possible to reverse the steps to have the master-password in clear text. It only requires more time than just an `echo $AUTO_SSH_CONFIG_MP`. Is up to the user to decide when/if that usage is safe enough.

### ssh via auto_ssh.sh
With many connections in _known_hosts_ it becomes difficult to remember all the _categories/nick1/nick2/nick3_. To have a short command line like 

```shell
auto_ssh.tcl -- -env cat1 n1 n2 n3
```
the names used _cat1/n1/n2/n3_ could be too short to be meaningful. If too long on the other hand, they require you to type more charatcters than the original ssh would have been. A solution is to have a wrapping script to launch `auto_ssh.tcl`.
This script is `auto_ssh.ssh`. It just provides a first shell `select` with the list of all the _categories_ found in `known_hosts`. It will provide further _selects_ for narrowing down on nick1/nick2/nick3.
That way no time is lost typing, neither any memory effort is spent remebering all the _categories/nicks_ which can be of any desired length in _known_hosts_.   

## TODO

remove the limitations.

