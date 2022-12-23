# Get-SpecifiedData

Just a little script with which I can specify (currently) files in XML which are then copied by the script to the destination 
(which is by default `$PSScriptRoot`).

## XML Syntax
Because the nature of the script is to copy / collect things from a (currently) local computer, the elements in the XML file reflect mainly
two things. First the path to the data object to copy:

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

This brings me to the second thing, the XML file reflects, which are the actions. Currently there is only the Copy action. But this can expand
in the future.

## Remarks
I havn`t tested the script in real life yet. Only provided a bunch of unittests so far. Keep that in mind, if you want to give it a try.
