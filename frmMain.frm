VERSION 5.00
Begin VB.Form frmMain 
   BorderStyle     =   1  'Fixed Single
   Caption         =   "Bitcoin key generator by The trick"
   ClientHeight    =   3615
   ClientLeft      =   45
   ClientTop       =   375
   ClientWidth     =   5175
   LinkTopic       =   "Form1"
   MaxButton       =   0   'False
   MinButton       =   0   'False
   ScaleHeight     =   3615
   ScaleWidth      =   5175
   StartUpPosition =   3  'Windows Default
   Begin VB.TextBox txtWIF 
      Height          =   495
      Left            =   60
      Locked          =   -1  'True
      TabIndex        =   4
      Top             =   1920
      Width           =   5055
   End
   Begin VB.TextBox txtAddress 
      Height          =   315
      Left            =   60
      Locked          =   -1  'True
      TabIndex        =   6
      Top             =   2700
      Width           =   5055
   End
   Begin VB.TextBox txtPublicKey 
      Height          =   495
      Left            =   60
      Locked          =   -1  'True
      TabIndex        =   2
      Top             =   1140
      Width           =   5055
   End
   Begin VB.CommandButton cmdGenerate 
      Caption         =   "Generate..."
      Height          =   435
      Left            =   3780
      TabIndex        =   8
      Top             =   3060
      Width           =   1335
   End
   Begin VB.TextBox txtPrivateKey 
      Height          =   555
      Left            =   60
      MultiLine       =   -1  'True
      TabIndex        =   1
      Top             =   300
      Width           =   5055
   End
   Begin VB.Label lblWIF 
      Caption         =   "WIF private:"
      Height          =   195
      Left            =   60
      TabIndex        =   7
      Top             =   1680
      Width           =   4995
   End
   Begin VB.Label lblAddress 
      Caption         =   "Address:"
      Height          =   195
      Left            =   60
      TabIndex        =   5
      Top             =   2460
      Width           =   4995
   End
   Begin VB.Label lblPublicKey 
      Caption         =   "Public key:"
      Height          =   195
      Left            =   60
      TabIndex        =   3
      Top             =   900
      Width           =   4995
   End
   Begin VB.Label lblPrivateKey 
      Caption         =   "Private key:"
      Height          =   195
      Left            =   60
      TabIndex        =   0
      Top             =   60
      Width           =   4995
   End
End
Attribute VB_Name = "frmMain"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

Private m_cGenerator    As CBTCGenerator

Private Sub cmdGenerate_Click()
    Dim bPrivate()  As Byte

    m_cGenerator.GenerateRandomPrivateKey bPrivate
    
    txtPrivateKey.Text = m_cGenerator.ToRawHex(bPrivate)
    
    Update
    
End Sub

Private Sub Form_Load()
    
    On Error GoTo error_handler
    
    Set m_cGenerator = New CBTCGenerator
    
    Exit Sub
    
error_handler:
    
    MsgBox "Unable to start program", vbCritical
    
    Unload Me
    
End Sub

Private Sub Form_Unload( _
            ByRef Cancel As Integer)
    
    Set m_cGenerator = Nothing
    
End Sub

Private Sub Update()
    Dim bPrivate()  As Byte
    Dim bPublic()   As Byte
    
    On Error GoTo error_handler
    
    bPrivate = m_cGenerator.FromRawHex(txtPrivateKey.Text)
    m_cGenerator.PublicKeyFromPrivate bPrivate, bPublic
    txtPublicKey.Text = m_cGenerator.ToRawHex(bPublic)
    txtAddress.Text = m_cGenerator.PublicKeyToAddress(bPublic)
    txtWIF.Text = m_cGenerator.PrivateKeyToWIF(bPrivate)
    
    Exit Sub
    
error_handler:
    
    MsgBox "Error", vbCritical
    
End Sub

Private Sub txtPrivateKey_KeyPress( _
            ByRef KeyAscii As Integer)
    
    If KeyAscii = 13 Then
        
        Update
        KeyAscii = 0
        
    End If
    
End Sub
