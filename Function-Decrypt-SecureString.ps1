Function Decrypt-SecureString { 
    param( 
        [Parameter(ValueFromPipeline=$true,
                    Mandatory=$true,
                    Position=0)] 
        [System.Security.SecureString]$SecureString 
    ) 
    begin {} 
    process { 
        $marshal = [System.Runtime.InteropServices.Marshal] 
        $ptr = $marshal::SecureStringToBSTR( $SecureString ) 
        $DecryptedString = $marshal::PtrToStringBSTR( $ptr ) 
        $marshal::ZeroFreeBSTR( $ptr ) 
        $DecryptedString 
        } 
    end {} 
    } 