Attribute VB_Name = "a_Texture"
Option Explicit


'texture array
Private Type texmap_type
    filename As String
    origrelfilename As String
    filesize As Long
    tex As GLuint
End Type
Public texmapnum As Long
Public texmap() As texmap_type


'loads texture from file
Public Function LoadTexture(ByVal filename As String, ByVal origrelfilename As String) As Long
    
    'you wouldn't believe how badly Windows handles slashes
    filename = Replace(filename, "/", "\")
    
    'check to see if already loaded
    Dim i As Long
    For i = 1 To texmapnum
        If texmap(i).filename = filename Then
            LoadTexture = i
            Exit Function
        End If
    Next i
    
    SetStatus "info", "Loading " & filename
    
    'add new texture
    texmapnum = texmapnum + 1
    ReDim Preserve texmap(1 To texmapnum)
    
    'load texture file
    Dim ext As String
    ext = LCase(GetFileExt(filename))
    Select Case ext
    Case "tga": texmap(texmapnum).tex = LoadTGA(filename)
    Case "dds": texmap(texmapnum).tex = LoadDDS(filename)
    End Select
    texmap(texmapnum).filename = filename
    texmap(texmapnum).origrelfilename = origrelfilename
    texmap(texmapnum).filesize = GetFileSize(filename)
    
    'success
    LoadTexture = texmapnum
End Function


'loads all mesh textures
Public Sub LoadMeshTextures()
    On Error GoTo errorhandler
    
Dim i As Long
Dim j As Long
Dim k As Long
Dim m As Long
Dim p As Long

Dim fname As String
Dim fpath As String
Dim mapfile As String
Dim filename As String
    
    'unload existing textures
    UnloadMeshTextures
    
    'load textures
    With vmesh
        If .loadok Then
            
            For i = 0 To .geomnum - 1
                For j = 0 To .geom(i).lodnum - 1
                    For k = 0 To .geom(i).lod(j).matnum - 1
                        
                        'try to load all maps
                        For m = 0 To .geom(i).lod(j).mat(k).mapnum - 1
                            
                            'clear texmapid
                            .geom(i).lod(j).mat(k).texmapid(m) = 0
                            
                            'get map filename
                            mapfile = .geom(i).lod(j).mat(k).map(m)
                            
                            If Len(mapfile) > 0 Then
                                
                                'reset path
                                filename = ""
                                
                                If opt_uselocaltexpath Then
                                    
                                    'try mesh path first
                                    fname = GetFilePath(vmesh.filename) & GetFileName(mapfile)
                                    If FileExist(fname) Then filename = fname
                                    
                                    'try mesh texture path
                                    If Len(filename) = 0 Then
                                        fname = GetFilePath(vmesh.filename) & "..\Textures\" & GetFileName(mapfile)
                                        If FileExist(fname) Then filename = fname
                                    End If
                                    
                                End If
                                
                                'try all of the texture folders
                                If Len(filename) = 0 Then
                                    fname = GetFileName(mapfile)
                                    For p = 1 To texpathnum
                                        If texpath(p).use Then
                                            
                                            Dim yname As String
                                            yname = texpath(p).path & "\" & mapfile
                                            If FileExist(yname) Then
                                               filename = yname
                                               Exit For
                                            End If
                                            
                                            Dim zname As String
                                            zname = texpath(p).path & "\" & fname
                                            If FileExist(zname) Then
                                               filename = zname
                                               Exit For
                                            End If
                                            
                                        End If
                                    Next p
                                End If
                                
                                'load texture
                                If Len(filename) > 0 Then
                                    'Echo "trying to load " & filename
                                    
                                    'If j = 0 Then
                                    '    MsgBox .geom(i).lod(j).mat(k).texmapid(m)
                                    'End If
                                    
                                    .geom(i).lod(j).mat(k).texmapid(m) = LoadTexture(filename, mapfile)
                                    
                                    BuildShader .geom(i).lod(j).mat(k), vmesh.filename
                                    
                                Else
                                    Echo "Texture " & Chr(34) & mapfile & Chr(34) & " not loaded!" & vbCrLf
                                End If
                                
                            End If
                            
                        Next m
                    
                    Next k
                Next j
            Next i
            
        End If
    End With
    
    'bf1942 standard mesh
    With stdmesh
        If .loadok And stdshader.loaded Then
            
            For i = 1 To stdshader.subshader_num
                With stdshader.subshader(i)
                    For p = 1 To texpathnum
                        If texpath(p).use Then
                            
                            fname = texpath(p).path & "\" & .texture & ".dds"
                            If FileExist(fname) Then
                                .texmapid = LoadTexture(fname, "")
                            End If
                            
                            fname = texpath(p).path & "\" & .texture & ".tga"
                            If FileExist(fname) Then
                                .texmapid = LoadTexture(fname, "")
                            End If
                            
                        End If
                    Next p
                End With
            Next i
            
        End If
    End With
    
    
    'bf1942 tree mesh
    With treemesh
        If .loadok Then
            
            For i = 0 To .meshnum - 1
                With .mesh(i)
                    For j = 0 To .matnum - 1
                        With .mat(j)
                            For p = 1 To texpathnum
                                If texpath(p).use Then
                                    
                                    fname = texpath(p).path & "\" & .texname & ".dds"
                                    If FileExist(fname) Then
                                        .texmapid = LoadTexture(fname, "")
                                    End If
                                    
                                End If
                            Next p
                        End With
                    Next j
                End With
            Next i
            
        End If
    End With
    
    
    Exit Sub
errorhandler:
    MsgBox "LoadMeshTextures" & vbLf & err.Description, vbCritical
End Sub


'unloads all mesh textures
Public Sub UnloadMeshTextures()
Dim i As Long
    For i = 1 To texmapnum
        texmap(i).filename = ""
        If texmap(i).tex <> 0 Then
            glDeleteTextures 1, texmap(i).tex
            texmap(i).tex = 0
        End If
    Next i
    Erase texmap()
    texmapnum = 0
End Sub


Public Sub BindTexture(ByVal id As Long)
    If id < 1 Or id > texmapnum Then
        UnbindTexture
        Exit Sub
    End If
    glBindTexture GL_TEXTURE_2D, texmap(id).tex
    glEnable GL_TEXTURE_2D
End Sub
Public Sub UnbindTexture()
    glBindTexture GL_TEXTURE_2D, 0
    glDisable GL_TEXTURE_2D
End Sub


'...
Public Function GetTextureMemory() As String
Dim total As Long
Dim i As Long
    For i = 1 To texmapnum
        total = total + texmap(i).filesize
    Next i
    GetTextureMemory = FormatFileSize(total)
End Function


'returns texture filename on disk
Public Function BF2GetTextureFilename(ByVal geo As Long, ByVal lod As Long, ByVal mat As Long, ByVal tex As Long) As String
    On Error GoTo errhandler
    
    If Not vmesh.loadok Then Exit Function
    If geo < 0 Then Exit Function
    If lod < 0 Then Exit Function
    If mat < 0 Then Exit Function
    If tex < 0 Then Exit Function
    
    If geo > vmesh.geomnum - 1 Then Exit Function
    If lod > vmesh.geom(geo).lodnum - 1 Then Exit Function
    If mat > vmesh.geom(geo).lod(lod).matnum - 1 Then Exit Function
    If tex > vmesh.geom(geo).lod(lod).mat(mat).mapnum - 1 Then Exit Function
    
    Dim texmapid As Long
    texmapid = vmesh.geom(geo).lod(lod).mat(mat).texmapid(tex)
    If texmapid > 0 Then
        BF2GetTextureFilename = texmap(texmapid).filename
    End If
    
    Exit Function
errhandler:
    MsgBox "BF2GetTextureFilename" & vbLf & err.Description, vbCritical
End Function