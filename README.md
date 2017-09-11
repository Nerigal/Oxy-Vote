# Oxy-Vote


Optimize your vote list for a minimum number of transaction vote queries  
Automatically exclude address from the list if you already votes for them to prevent error code return from the API 
Multiple Signature compatible 
Default test mode On... You have to confirm to make sure the transaction is apply.

# Add Voting mode

vote from a text file list based on oxy address

`oxy-vote -HostUrl https://server.example.com -address <YOUR_oxy_ADDRESS> -Secret '<SECRET_PASSPHRASE_HERE>' -SecondSecret '<SECOND_SECRET_PASSPHRASE_HERE>' -file 'C:\Users\whatever\documents\vote.log' -DataType address -verbose`

vote from a text file list based on Delegate Names

`oxy-vote -HostUrl https://server.example.com -address <YOUR_oxy_ADDRESS> -Secret '<SECRET_PASSPHRASE_HERE>' -SecondSecret '<SECOND_SECRET_PASSPHRASE_HERE>' -file 'C:\Users\whatever\documents\vote.log' -DataType DelegateName -verbose`


# Remove Voting mode 

Remove from a text file list based on oxy address 

`oxy-vote -HostUrl https://server.example.com -address <YOUR_oxy_ADDRESS> -Secret '<SECRET_PASSPHRASE_HERE>' -SecondSecret '<SECOND_SECRET_PASSPHRASE_HERE>' -file 'C:\Users\whatever\documents\devote.log' -DataType address -Remove:$true -verbose`

Remove from a text file list based on Delegate Names

`oxy-vote -HostUrl https://server.example.com -address <YOUR_oxy_ADDRESS> -Secret '<SECRET_PASSPHRASE_HERE>' -SecondSecret '<SECOND_SECRET_PASSPHRASE_HERE>' -file 'C:\Users\whatever\documents\devote.log' -DataType DelegateName -Remove:$true -verbose`

 
