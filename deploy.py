def reverse_words(sentence):
    result = ""
    word = "" 
    for char in sentence:
        if char != " ":
            word += char
        else:
            result += word[::-1] + " "
            word   = ""

    result += word[::-1]
    return result


input_sentence = "this is a test"
output_sentence = reverse_words(input_sentence)

print(output_sentence)



