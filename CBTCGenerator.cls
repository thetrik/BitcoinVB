VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "CBTCGenerator"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
' //
' // CBTCGenerator.cls - generate bitcoin (BTC) keys/addresses
' //

Option Explicit

Private Const CRYPT_VERIFYCONTEXT As Long = &HF0000000
Private Const PROV_RSA_FULL       As Long = 1

Private Declare Function CryptAcquireContext Lib "advapi32.dll" _
                         Alias "CryptAcquireContextW" ( _
                         ByRef phProv As Long, _
                         ByVal pszContainer As Long, _
                         ByVal pszProvider As Long, _
                         ByVal dwProvType As Long, _
                         ByVal dwFlags As Long) As Long
Private Declare Function CryptReleaseContext Lib "advapi32.dll" ( _
                         ByVal hProv As Long, _
                         ByVal dwFlags As Long) As Long
Private Declare Function CryptGenRandom Lib "advapi32.dll" ( _
                         ByVal hProv As Long, _
                         ByVal dwLen As Long, _
                         ByRef pbBuffer As Any) As Long
Private Declare Sub memcpy Lib "kernel32" _
                    Alias "RtlMoveMemory" ( _
                    ByRef Destination As Any, _
                    ByRef Source As Any, _
                    ByVal Length As Long)


Private m_hCryptProv    As Long
Private m_hCtx          As Long

Public Function PrivateKeyToWIF( _
                ByRef bData() As Byte) As String
    Dim bSha256()   As Byte
    Dim bResult()   As Byte
    
    ReDim bSha256(31)
    ReDim bResult(37)
    
    memcpy bResult(1), bData(0), UBound(bData) + 1
    
    bResult(0) = &H80
    bResult(33) = 1     ' // Compressed
    
    sha256 bResult(0), 34, bSha256(0)
    sha256 bSha256(0), 32, bSha256(0)

    bResult(34) = bSha256(0)
    bResult(35) = bSha256(1)
    bResult(36) = bSha256(2)
    bResult(37) = bSha256(3)
    
    PrivateKeyToWIF = ToBase58(bResult)
    
End Function

Public Function PublicKeyToAddress( _
                ByRef bData() As Byte) As String
    Dim bSha256()       As Byte
    Dim bRipMD160Pref() As Byte
    
    ReDim bSha256(31)
    ReDim bRipMD160Pref(24)
    
    sha256 bData(0), UBound(bData) + 1, bSha256(0)
    ripemd160 bSha256(0), 32, bRipMD160Pref(1)
                    
    bRipMD160Pref(0) = 0    ' // Main net
    
    sha256 bRipMD160Pref(0), 21, bSha256(0)
    sha256 bSha256(0), 32, bSha256(0)
    
    bRipMD160Pref(21) = bSha256(0)
    bRipMD160Pref(22) = bSha256(1)
    bRipMD160Pref(23) = bSha256(2)
    bRipMD160Pref(24) = bSha256(3)
                  
    PublicKeyToAddress = ToBase58(bRipMD160Pref)
    
End Function

Public Sub PublicKeyFromPrivate( _
           ByRef bPrivate() As Byte, _
           ByRef bPublicOut() As Byte)
    Dim tPubKey As secp256k1_pubkey
    
    If m_hCtx = 0 Then
        Err.Raise 5, "CBTCGenerator::GenerateRandomPrivateKey", "Context isn't initialized"
    End If
    
    If secp256k1_ec_pubkey_create(m_hCtx, tPubKey, bPrivate(0)) = 0 Then
        Err.Raise 5, "CBTCGenerator::GenerateRandomPrivateKey", "secp256k1_ec_pubkey_create failed"
    End If
               
    ReDim bPublicOut(32)
    
    If secp256k1_ec_pubkey_serialize(m_hCtx, bPublicOut(0), 33, tPubKey, SECP256K1_EC_COMPRESSED) = 0 Then
        Err.Raise 5, "CBTCGenerator::GenerateRandomPrivateKey", "secp256k1_ec_pubkey_serialize failed"
    End If
               
End Sub

Public Sub GenerateRandomPrivateKey( _
           ByRef bData() As Byte)
    
    If m_hCryptProv = 0 Then
        Err.Raise 5, "CBTCGenerator::GenerateRandomPrivateKey", "Provider isn't initialized"
    End If
    
    ReDim bData(31)
    
    Do
    
        If CryptGenRandom(m_hCryptProv, 32, bData(0)) = 0 Then
            Err.Raise 5, "CBTCGenerator::GenerateRandomPrivateKey", "CryptGenRandom failed 0x" & Hex$(Err.LastDllError)
        End If
    
    Loop Until secp256k1_ec_seckey_verify(m_hCtx, bData(0))
    
End Sub

Public Function FromRawHex( _
                ByVal sValue As String) As Byte()
    Dim lIndex      As Long
    Dim lChIndex    As Long
    Dim lChar       As Long
    Dim lValue      As Long
    Dim lNibble     As Long
    Dim bIn()       As Byte
    Dim bOut()      As Byte
    
    bIn = sValue
    
    For lChIndex = 0 To Len(sValue) - 1
        
        lChar = bIn(lChIndex * 2) Or (CLng(bIn(lChIndex * 2 + 1)) * &H100)
        
        Select Case lChar
        Case &H30 To &H39
            lChar = lChar - &H30
        Case &H41 To &H46
            lChar = lChar - &H37
        Case &H61 To &H66
            lChar = lChar - &H57
        Case &H20, &HA, &HD, &H9
            
            If lNibble = 1 Then
                Err.Raise 5, "CBTCGenerator::FromRawHex", "Invalid input string"
            End If
            
            GoTo continue
            
        Case Else
            Err.Raise 5, "CBTCGenerator::FromRawHex", "Invalid input string"
        End Select
        
        lValue = (lValue * &H10) Or lChar
        
        If lNibble Then
            
            If lIndex Then
                If lIndex > UBound(bOut) Then
                    ReDim Preserve bOut(lIndex + 16)
                End If
            Else
                ReDim bOut(15)
            End If
            
            bOut(lIndex) = lValue
            
            lIndex = lIndex + 1
            lNibble = 0:    lValue = 0
            
        Else
            lNibble = lNibble + 1
        End If
        
continue:
        
    Next
    
    If lNibble = 1 Then
        Err.Raise 5, "CBTCGenerator::FromRawHex", "Invalid input string"
    End If
            
    If lIndex Then
        ReDim Preserve bOut(lIndex - 1)
    Else
        Erase bOut
    End If
                    
    FromRawHex = bOut
                    
End Function

Public Function ToRawHex( _
                ByRef bData() As Byte) As String
    Dim bOut()  As Byte
    Dim lIndex  As Long
    Dim lValue  As Long
    Dim lChar   As Long
    Dim lNibble As Long
    
    ReDim bOut((UBound(bData) + 1) * 4 - 1)
    
    For lIndex = 0 To UBound(bData)
    
        lValue = bData(lIndex)
        
        For lNibble = 1 To 0 Step -1
                   
            lChar = lValue And &HF
            
            Select Case lChar
            Case Is < 10:   lChar = lChar + &H30
            Case Else:      lChar = lChar + &H57
            End Select
            
            bOut(lIndex * 4 + lNibble * 2) = lChar
            
            lValue = lValue \ &H10
            
        Next
        
    Next
    
    ToRawHex = bOut
    
End Function

' // Code based on https://github.com/bitcoin/libbase58/blob/master/base58.c
Public Function ToBase58( _
                ByRef bData() As Byte) As String
    Dim lZCount     As Long
    Dim lBufSize    As Long
    Dim bBuf()      As Byte
    Dim lI          As Long
    Dim lJ          As Long
    Dim lCarry      As Long
    Dim lHigh       As Long
    
    Const BASE58_ALPHABET   As String = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"

    Do While (lZCount <= UBound(bData))
    
        If bData(lZCount) Then Exit Do
        lZCount = lZCount + 1
        
    Loop
                     
    lBufSize = ((UBound(bData) + 1) - lZCount) * 138 / 100 + 1
    
    ReDim bBuf(lBufSize - 1)
    
    lHigh = lBufSize - 1
    
    For lI = lZCount To UBound(bData)
        
        lJ = lBufSize - 1
        lCarry = bData(lI)

        Do While (lJ > lHigh) Or lCarry
            
            lCarry = lCarry + (&H100& * bBuf(lJ))
            bBuf(lJ) = lCarry Mod 58
            lCarry = lCarry \ 58
            
            If lJ = 0 Then Exit Do
            
            lJ = lJ - 1
            
        Loop
        
        lHigh = lJ
        
    Next
    
    For lJ = 0 To lBufSize - 1
        If bBuf(lJ) Then Exit For
    Next
    
    If lZCount Then
        ToBase58 = String$(lZCount, "1")
    End If
    
    For lI = lJ To lBufSize - 1
        ToBase58 = ToBase58 & Mid$(BASE58_ALPHABET, bBuf(lI) + 1, 1)
    Next

End Function

Private Sub Class_Initialize()
    
    If CryptAcquireContext(m_hCryptProv, 0, 0, PROV_RSA_FULL, CRYPT_VERIFYCONTEXT) = 0 Then
        Err.Raise 7, "CBTCGenerator::Class_Initialize", "CryptAcquireContext failed 0x" & Hex$(Err.LastDllError)
        Exit Sub
    End If
    
    m_hCtx = secp256k1_context_create(SECP256K1_CONTEXT_SIGN Or SECP256K1_CONTEXT_VERIFY)
    If m_hCtx = 0 Then
        Err.Raise 7, "CBTCGenerator::Class_Initialize", "secp256k1_context_create failed"
        Exit Sub
    End If
    
End Sub

Private Sub Class_Terminate()
    
    If m_hCryptProv Then
        CryptReleaseContext m_hCryptProv, 0:    m_hCryptProv = 0
    End If
    
    If m_hCtx Then
        secp256k1_context_destroy m_hCtx:   m_hCtx = 0
    End If
    
End Sub
