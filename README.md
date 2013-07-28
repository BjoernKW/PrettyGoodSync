PrettyGoodSync
==============

PrettyGoodSync allows you to associate your address book contacts with their respective GPG / PGP public key files.

The [fetch_public_keys_for_contacts.rb](https://github.com/BjoernKW/PrettyGoodSync/blob/master/fetch_public_keys_for_contacts.rb "fetch_public_keys_for_contacts.rb") script takes the name of a vCard file and a directory path as parameters and then searches the [MIT public key server](http://pgp.mit.edu/ "MIT PGP Public Key Server") for each eMail address in that vCard file. If an entry is found the script will download the public key as an ASCII-armoured file (.asc).
