--!strict

return {
    num_info = {
        unsigned_int = function(min : number?, max : number?) return {
            int = true,
            signed = false,
            limit = {
                max = 4294967295,
                min = 0
            }
        } end,

        signed_int = {
            int = true,
            signed = true,
            limit = {
                max = 2147483647,
                min = -2147483648
            }
        },

        float = {
            int = false,
            signed = true,
            limit = {
                max = 3.402823466e+38,
                min = -3.402823466e+38
            }
        }   
    }
}