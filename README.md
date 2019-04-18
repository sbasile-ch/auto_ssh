# Auto SSH

This [expect](https://en.wikipedia.org/wiki/Expect) script allows to auto __ssh__ into a server providing just an alias for that connection. It automatically fills the password for that connection, asking instead the __master password__ of where all the _passwords_ are stored. They are stored in an encrypted file, so that, obtaining any of them, requires to decrypt it via a _master password_. Remembering a single _password_ without bothering to remember every single connection's _password_ is  one aim of this auto-ssh. For not critical connections, the script accepts an alternative ways to provide the _master password_ having it stored in an ENV variable for full automatic login.

## requisites

* [expect](https://en.wikipedia.org/wiki/Expect)
* unix `shell` ( `bash/csh/zsh/` ...)
* `openssl`   (Being ssh built on top of openssl there should be no issue for this)

## limitations

* It requires `openssl` which could be not available for _SSH_ version not built on top of it.

* There is no way, currently, to have more than 1 _passwords-file_ (and so different _master passwords_ for each).

* being an [expect](https://en.wikipedia.org/wiki/Expect) script, the script's flags (ex __-d__
and __-c__ or __-h__) are parsed still by _expect_ itself and not forwarded to be parsed separately. They then need to be preceeded by the usual end-of-options sequence: "--"
This means that instead of just `auto_ssh -d clear.txt -mp` I must type `auto_ssh -- -d clear.txt -mp`

## installation

1. git clone somewhere (ex from your home directory, so that it will create the sub directory _auto_ssh_ within everything included)

2. make sure it is accessible:
     * adding its containing dir in `$PATH` (`PATH="${PATH}:${HOME}/auto_ssh"`)
     * or aliasing it `alias as="${HOME}/auto_ssh/assh"`

3. likely you need to set exec permissions `chmd +x ${HOME}/auto_ssh/assh`

## usages

### create a passwords-file

first create a clear _text_ file, containing the desired passwords (ex. [passwords.txt](https://github.com/sbasile-ch/auto_ssh/blob/master/passwords.txt) ). The structure of this file is just a list of lines (1 for each password) with every line having this shape:
```shell
        alias   ,password
```
thus, 2 tokens separated by blanks (spaces or tabs) and 1 comma `,`. 
The __first__ token (`alias`) is how the password is _aliased_ in the connection definition in the [known-hosts](https://github.com/sbasile-ch/auto_ssh/blob/master/known_hosts).
Ex of connection:
```shell
        chic, b, 7, , chicbeplive, chicweb1v.orctel.internal,    alias
```
The __second__ token is the password in clear text.

__NOTE THAT THE PASSWORD IS ANYTHING AFTER THE COMMA.__ This allows to have any kind of password (spaces included) and any starting ending chars which cannot clash with any delimiting chars (as they are not present). So __be careful__ if you leave any spaces at the end of a password, because they will be taken __as part of it__.

Once the text file has been completed, you need to encrypt it:
```shell
assh -- -c passwords.txt
```
Providing a master-password at this stage, will encrypt the clear text file into a `psw.enc` in the directory where `assh` is installed (ex. `${HOME}/auto_ssh/psw.enc`)

It's always better to remove the clear text file and to leave nothing un-encrypted.

### show the passwords-file

To dump clearly the content of the encrypted passwords-file, run:

```shell
assh -- -d passwords.txt
```

This will prompt for the _master password_ and, if it is correct, it will decrypt the content into the clear text file _passwords.txt_. This can be useful for changing the current password-file, in a sequence of decrypt/change/re-encrypt.


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
assh chic b 7
```

and typing password __abc__, instead of typing

```shell
ssh chicbeplive@chicweb1v.orctel.internal
```

and password __pass123xxx__


### ssh with no master-password typed

It's possible to `ssh` into a server with no password typed at all, providing the flag `-mp`

```shell
assh -- -mp chic b 7       #note the '--' as explained in the limitations
```
What the `-mp` flag does, is to read the _master-password_ from the `ENV` variable whose name is the value of `CONFIG_MP` in [config](https://github.com/sbasile-ch/auto_ssh/blob/1f894d89025eb40f4e42917e5d5b5b290ba9a105/config#L6) 
So if the _config_ has this entry
```shell
set CONFIG_MP       "AUTO_SSH_CONFIG_MP"      
```
the _master-password_ will be the value of `$AUTO_SSH_CONFIG_MP`
Acutally to have it not in clear text (which could just be shown with an `env` command), there is a tiny intermidiate step of encryption/decryption of that value.
The encryption key used is the value of `CONFIG_MP_KEY` in the [config](https://github.com/sbasile-ch/auto_ssh/blob/1f894d89025eb40f4e42917e5d5b5b290ba9a105/config#L5) file
The 2 steps to use the `-mp` flag would then be:

```shell
# 1. - define an encrypted value for the master password
assh -- -cmp   # suppose it returns [U2FsdGVkX19en7cv1Mv/0E1xaFgM4lvLt1Hg+o69Le8=]

# 2. - assign that value to the variable named in CONFIG_MP 
export AUTO_SSH_CONFIG_MP=U2FsdGVkX19en7cv1Mv/0E1xaFgM4lvLt1Hg+o69Le8=
```

Of course it's still possible to reverse the steps to have the master-password in clear text. It only requires more time than just an `echo $AUTO_SSH_CONFIG_MP`. Is up to the user to decide when/if that usage is safe enough.

## TODO

remove the limitations.

