# Get-SpecifiedData

Just a little script with which I can specify (currently) files in XML which are then copied by the script to the destination
(which is by default `$PSScriptRoot`).

## XML Syntax
Because the nature of the script is to copy / collect things from a (currently) local computer, the elements in the XML file reflect mainly
two things. First the path to the data object to copy:

### Collection Path
```
<C:_>
    <users_someuser>
        <action-copy-file>SomeFile.txt</action-copy-file>
    </users_someuser>
</C:_>
```
In the example the script would firstly detect that the script runs on a Windows machine, so it would replace all the `_` with `\` while it
traverses down the element tree. When it reaches an action, marked with `action-` in the element name it already has the path constructed,
where the file should be, which is `C:\users\someuser\` and it will collect the file `SomeFile.txt` from that path, at least it tries to.


### Collection Action
This brings me to the second thing, the XML file reflects, which are the actions. Currently there is only the Copy action. But this can expand
in the future.
It would take the complete `Action`-element as an input parameter for the function which implements the action. So there is plenty of room to
pull in parameters, settings etc.

## Specified Data
As mentioned in [Collection Path](#collection-path), you can define the path from where to collect data by the help of the names of the XML elements themselfs. There is only the problem with wildcards '*' and the local folder '.'. For that the script will replace special placeholder strings with them. Just see the examples below.

### Localfolder Placeholder
```
<!-- Will result in './test' --!>
<LOCALFOLDER-_test>
    ...
<LOCALFOLDER-_test>
```
`LOCALFOLDER-` must stand at the beginning of the element name and will be replaced with `.`.

### Wildcard Placeholder
```
<!-- Will result in 'test*test' --!>
<_testWILD-test>
    ...
<_testWILD-test>
```
`WILD-` is allowed everywhere in the element name and will be replaced with `*`.

## Remarks
I havn`t tested the script in real life yet. Only provided a bunch of unittests so far. Keep that in mind, if you want to give it a try.
