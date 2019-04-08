# Auto SSH
This [expect](https://en.wikipedia.org/wiki/Expect) script allows to auto __ssh__ into a server providing just an alias for that connection. It automatically fills the password for that connection, asking instead the 'master password' of where all the _passwords_ are stored. They are stored in an encrypted file, so that, obtaining any of them, requires to decrypt it via a __master password__. Remembering a single _password_ without bothering to remember every single connection's _password_ is the one aim of this auto-ssh. For not critical connections, future versions of this script could accept alternative ways to provide the _master password_ having then a full automatic login.

## requisites
* [expect](https://en.wikipedia.org/wiki/Expect)
* unix `shell` ( `bash/csh/zsh/` ...)
* `openssl`   (Being ssh built on top of openssl there should be no issue for this)

## limitations
* It requires openssl which could be not available for SSH version not built on top of it.

* There is no way, currently, to provide the master password if not just typing it. Ongoing development intends to relax this constraint, storing the master password somwhere (`ENV-var`, `file`, ...) and requiring no sort of interactive input at all. This could be usefull, for not critical connections, espcecially once also the feature to have more than 1 passwords-file (and so different master passwords for each) will be implemented.

* Currently there is in fact only 1 passwords-file (with its own master password)

* being an [expect](https://en.wikipedia.org/wiki/Expect) script, the script's flags (ex __-d__
and __-c__ or __-h__) are parsed still by expect itself and not forwarded to be parsed separatedly. They then need to be preceeded by the usual end of option sequence: "--"

## installation
1. git clone somewhere (ex from your home directory, so that it will create the sub directory _auto_ssh_ within everything included)

2. make sure it is accessible:
     * adding its containing dir in `$PATH` (`PATH="${PATH}:${HOME}/auto_ssh"`)
     * or aliasing it `alias as="${HOME}/auto_ssh/assh"`

3. likely you need to set exec permissions `chmd +x ${HOME}/auto_ssh/assh`

## usages

### create a passwords-file
first create a clear text file, containing the desired passwords (ex. [passwords.txt](https://github.com/sbasile-ch/auto_ssh/blob/master/passwords.txt) ). The structure of this file is just a list of lines (1 for each password) with every line having this shape:
```shell
        alias   ,password
```
so 2 tokens separated by blanks (spaces or tabs) and 1 comma `,`. The first token (`alias`) is how the password is _aliased_ in the connection definition in the [known-hosts](https://github.com/sbasile-ch/auto_ssh/blob/master/known_hosts) file.
Ex of connection:
```shell
        chic, b, 7, , chicbeplive, chicweb1v.orctel.internal,    alias
```
The second token is the password in clear text.

__NOTE THAT THE PASSWORD IS ANYTHING AFTER THE COMMA.__ This allows to have any kind of password (spaces included) and any starting ending chars which cannot clash with any delimiting chars (as they are not present). So __be careful__ if you leave any spaces at the end of a password because they will be taken as part of it.

Once the text file has been completed you need to encrypt it:
```shell
assh -- -c passwords.txt
```
Providing a master-password at this stage, it will encrypt the clear text file into a `psw.enc` file in the directory where `assh` is installed (ex. `${HOME}/auto_ssh/psw.enc`)

It's always better to remove the clear text file and leave nothing un-encrypted.

### show the passwords-file
To dump clearly the content of the encrypted passwords-file, run:

```shell
assh -- -d passwords.txt
```

This will prompt for the master password and, if it is correct, it will decrypt the content into the clear text file _passwords.txt_. This can be useful to perfrom any changes and then to re-encrypt it.


### ssh directly into a connection
For any configured connection in [known-hosts](https://github.com/sbasile-ch/auto_ssh/blob/master/known_hosts), and password in `psw.enc`, is then possible to auto **ssh** to that `username@server` providing the nick of the connection and the master password.
ex.
fot the following connection in [known-hosts](https://github.com/sbasile-ch/auto_ssh/blob/master/known_hosts)
```shell
        chic, b, 7, , chicbeplive, chicweb1v.orctel.internal,    alias45
```
and following entry encrypted in _psw.enc_   (with for example a master password __abc__)
```shell
            alias45    ,pass123xxx
```

It's possible to _ssh_ directly as
```shell
assh chic b 7
```

and typing password __abc__, instead of typing

```shell
ssh chicbeplive@chicweb1v.orctel.internal
```

and password __pass123xxx__

## TODO

remove the limitations.

