Describe 'Module Manifest Tests' {
    It 'Passes Test-ModuleManifest' {
        Test-ModuleManifest -Path './DataCollector.psd1' | Should -Not -BeNullOrEmpty
        $? | Should -Be $true
    }
}

Import-Module './DataCollector.psm1' -Force

InModuleScope DataCollector {
    # Define the tests
    Describe 'Traverse_Specification' {
        # mock Invoke_Action
        Mock Invoke_Action { Write-Verbose "Invoke_Action called" }
        # Test 1: Check if the function traverses the entire XML file
        It 'Traverses the entire XML file' {

            #Get-Command -Module 'DataCollector' | Where-Object { -Not $_.IsExportable }
            # Define the input XML file
            $xml = [xml]@"
                <_root>
                    <node1>
                        <node1.1>Value 1.1</node1.1>
                        <node1.2>Value 1.2</node1.2>
                    </node1>
                    <node2>Value 2</node2>
                    <node3>Value 3</node3>
                </_root>
"@

            # Capture the output of the TraverseXml function
            $tmp = $VerbosePreference
            $VerbosePreference = 'Continue'
            $output = Traverse_Specification $xml.DocumentElement 4>&1
            $VerbosePreference = $tmp

            # Assert the output
            $output[1].Message | Should -be "/root/"
            $output[3].Message | Should -be "/root/node1/"
            $output[5].Message | Should -be "/root/node1/node1.1/"
            $output[6].Message | Should -be "/root/node1/"
            $output[8].Message | Should -be "/root/node1/node1.2/"
            $output[9].Message | Should -be "/root/node1/"
            $output[10].Message | Should -be "/root/"
            $output[12].Message | Should -be "/root/node2/"
            $output[13].Message | Should -be "/root/"
            $output[15].Message | Should -be "/root/node3/"
            $output[16].Message | Should -be "/root/"
        }

        # Test 2: Check if the function correctly handles empty nodes
        It 'Handles empty nodes correctly' {
            # Define the input XML file
            $xml = [xml]@"
                <root>
                    <node1>
                        <node1.1></node1.1>
                        <node1.2></node1.2>
                    </node1>
                    <node2></node2>
                    <node3></node3>
                </root>
"@

            # Capture the output of the TraverseXml function
            $tmp = $VerbosePreference
            $VerbosePreference = 'Continue'
            $output = Traverse_Specification $xml.DocumentElement 4>&1
            $VerbosePreference = $tmp

            # Assert the output
            $output[1].Message | Should -be  "root/"
            $output[3].Message | Should -be  "root/node1/"
            $output[5].Message | Should -be  "root/node1/node1.1/"
            $output[6].Message | Should -be  "root/node1/"
            $output[8].Message | Should -be  "root/node1/node1.2/"
            $output[9].Message | Should -be  "root/node1/"
            $output[10].Message | Should -be  "root/"
            $output[12].Message | Should -be  "root/node2/"
            $output[13].Message | Should -be  "root/"
            $output[15].Message | Should -be  "root/node3/"
            $output[16].Message | Should -be  "root/"
        }

        AfterAll {
            $script:variables["collectpath"] = ""
        }
    }

    Describe 'Get-RootPlaceholder' {
        It 'returns :\ when run on Windows' {
            Mock Get_RunningPlatform {
                return "Microsoft Windows 10.0.18362"
            }

            $placeholder = Get_PathSeperator

            $placeholder | Should -be "\"
        }

        It 'returns / on any platform except Windows' {
            Mock Get_RunningPlatform {
                return "Darwin 12345"
            }

            $placeholder = Get_PathSeperator

            $placeholder | Should -be "/"
        }
    }

    Describe 'Update_CollectPath' {
        It 'should append root element for windows' {
            Mock Get_RunningPlatform {
                return "Microsoft Windows 10.0.18362"
            }

            Update_CollectPath -nodeName "C:_"

            $script:variables["collectpath"] | should -be "C:\"
        }

        It 'should append root element for other platforms' {
            Mock Get_RunningPlatform {
                return "Darwin Windows 10.0.18362"
            }

            Update_CollectPath -nodeName "_"∏

            $script:variables["collectpath"] | should -be "/"
        }

        It 'should remove the part of the child node name' {
            Mock Get_RunningPlatform {
                return "Darwin Windows 10.0.18362"
            }

            $script:variables["collectpath"] = "/hello/world/test/test/"
            Update_CollectPath -childNodeName "test_test"

            $script:variables["collectpath"] | should -be "/hello/world/"
        }

        AfterEach {
            $script:variables["collectpath"] = ""
        }
    }
}

# three unittests for the function Ensure_Seperator in the module DataCollector.
# Use $script:variables["collectpath"] to access the variable collectpath in the module
InModuleScope DataCollector {
    Describe 'Ensure_Seperator' {
        It 'should add a seperator if the collectpath is not empty' {
            $script:variables["collectpath"] = "/hello/world"
            Ensure_Seperator

            $script:variables["collectpath"] | should -be "/hello/world/"
        }

        It 'should not add a seperator if the collectpath is empty' {
            $script:variables["collectpath"] = ""
            Ensure_Seperator

            $script:variables["collectpath"] | should -be ""
        }

        It 'should not add a seperator if the collectpath is already seperated' {
            $script:variables["collectpath"] = "/hello/world/"
            Ensure_Seperator

            $script:variables["collectpath"] | should -be "/hello/world/"
        }

        AfterEach {
            $script:variables["collectpath"] = ""
        }
    }
}

# unittests for the function Initialize_DestinationPath in the module DataCollector.
# Use $script:variables["destinationpath"] to access the variable destinationpath in the module
InModuleScope DataCollector {
    Describe 'Initialize_DestinationPath' {
        It 'should set the destinationpath to the default value, which is $PSScriptRoot, if no path is given' {
            # Get $PSScriptRoot during testing includes the leaf folder "test"
            # Remove the leaf folder "test" from $PSScriptRoot
            $excpected = $PSScriptRoot -replace "/test", ""
            Initialize_DestinationPath

            $script:variables["destinationpath"] | should -be $excpected
        }

        It 'should set the destinationpath to the given path' {
            Initialize_DestinationPath -destinationPath "C:\test"

            $script:variables["destinationpath"] | should -be "C:\test"
        }

        AfterEach {
            $script:variables["destinationpath"] = ""
        }
    }
}

# unittests for the function Is_Action in the module DataCollector.
InModuleScope DataCollector {
    Describe 'Is_Action' {
        It 'should return true if the given node is an action' {
            $node = [Xml]@"
                <action-copy>
                    <name>test</name>
                    <description>test</description>
                    <command>test</command>
                </action-copy>
"@
            $result = Is_Action $node.DocumentElement

            $result | should -be $true
        }

        It 'should return false if the given node is not an action' {
            $node = [Xml]@"
            <test>
                <name>test</name>
                <description>test</description>
                <command>test</command>
            </test>
"@
            $result = Is_Action $node.DocumentElement

            $result | should -be $false
        }
    }
}

# unittests for the function Copy-File in the module DataCollector.
# mock the call to Copy-Item as simple as possible
# use xml "<test>test.txt</test>" as input
# use "./test/testfiles/test.txt" as source
# use "./test/testfiles/testdestination" as destination
# only use the parameter -node to call the function
InModuleScope DataCollector {
    Describe 'Copy-File' {
        It 'should copy the file to the destination' {
            Mock Copy_File {}
            Mock Get-Item {}

            $node = [Xml]@"
                <test>test.txt</test>
"@
                $script:variables["destinationpath"] = "./test/testfiles/testdestination"
                $script:variables["collectpath"] = "./test/testfiles/"
                Copy-File -node $node.DocumentElement
        }

        # test what happens if the file already exists
        It 'should not copy the file if it already exists' {
            Mock Copy_File {}
            Mock Get-Item {}

            $node = [Xml]@"
                <test>test.txt</test>
"@
                $script:variables["destinationpath"] = "./test/testfiles/testdestination"
                $script:variables["collectpath"] = "./test/testfiles/"
                Copy-File -node $node.DocumentElement

                $script:variables["destinationpath"] = "./test/testfiles/testdestination"
                $script:variables["collectpath"] = "./test/testfiles/"
                Copy-File -node $node.DocumentElement
        }

        # test the error handling
        It 'should throw an error if the file does not exist' {
            Mock Copy_File {}
            Mock Get-Item {}

            $node = [Xml]@"
                <test>test2.txt</test>
"@
                $script:variables["destinationpath"] = "./test/testfiles/testdestination"
                $script:variables["collectpath"] = "./test/testfiles/"
                { Copy-File -node $node.DocumentElement } | Should -Throw
        }

        AfterEach {
            $script:variables["destinationpath"] = ""
            $script:variables["collectpath"] = ""
        }
    }
}