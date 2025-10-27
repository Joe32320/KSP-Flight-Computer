function drawVector{
    declare parameter from.
    declare parameter to.
    declare parameter name to "".
    declare parameter color to white.
    
    return vecdraw(from, to, color, name, 1, true, 0.2).
}