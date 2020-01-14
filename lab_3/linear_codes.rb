# ===================
# !IMPORTANT WARNING!
# THIS CODE IS A DIRECT ANTI PATTERN AND DEMONSTRATES
# HOW PROGRAMS CAN'T BE WRITTEN CATEGORICALLY.
# IF YOU INTEND TO USE THIS CODE, I STRONGLY RECOMMEND YOU
# TO RECONSTRUCT IT AND REWRITE IN ACCORDANCE WITH BASE
# STANDARDS FOR CLEAN CODE AND RUBY STYLE GUIDE.
# FOR MY PART, I DON'T GUARANTEE ITS PERFORMANCE AND
# DON'T HOLD RESPONSIBLE FOR A CRYSTAL CLEAN READING.
# !THANK YOU!
# ===================

WORD_LENGTH = 4
CODE_WORD_LENGTH = 7
POLYNOM = '1011'.freeze

def revert_chars_by_index(str, index)
  chars = str.chars
  if index.negative?
    chars.insert(0, '1')
  elsif
    chars[index] = chars[index] == '1' ? '0' : '1'
  else
    chars << '1'
  end

  chars.join
end

def calc_difference(num, other)
  result, les_num = num.size > other.size ? [num, other] : [other, num]
  les_num.size.times do |index|
    num_place = les_num.size - 1 - index
    result_place = result.size - 1 - index
    result = if result[result_place] == '1' && les_num[num_place] == '1'
               revert_chars_by_index(result, result_place)
             elsif les_num[num_place] == '1'
               revert_chars_by_index(result, result_place)
             else
               result
             end
  end
  result_len = result.size - 1
  result_len.times do
    result[0].to_i.zero? ? result = result[1..result.size] : break
  end

  result
end

def mod(num, other)
  return num if %w[1 10 100].include?(num) && other.size > num.size

  if num.size > other.size
    len_differ = num.size - other.size
    first_divider = other
    len_differ.times { first_divider += '0' }
    diff = calc_difference(num, first_divider)
    while diff.size >= other.size
      new_divider = other
      len_differ = diff.size - other.size
      len_differ.times { new_divider += '0' }
      diff = calc_difference(diff, new_divider)
    end

    return diff
  end

  calc_difference(num, other)
end

if $PROGRAM_NAME == __FILE__
  word = '1'
  (WORD_LENGTH - 1).times { word += rand(2).to_s }
  puts "Code word: #{word}"
  (CODE_WORD_LENGTH - WORD_LENGTH).times { word += '0' }
  code = calc_difference(word, mod(word, POLYNOM))
  puts "Encoded word: #{code}"
  puts "Mod: #{mod(code, POLYNOM)}"
  rand_place = rand(code.size - 1)
  code = revert_chars_by_index(code, rand_place)
  puts "Word with noize: #{code}"
  puts "Mod: #{mod(code, POLYNOM)}"
  remains = mod(code, POLYNOM)
  CODE_WORD_LENGTH.times do |i|
    temp_mistake = '1'
    i.times { temp_mistake += '0' }
    temp_mistake_remains = mod(temp_mistake, POLYNOM)
    if remains == temp_mistake_remains
      code = revert_chars_by_index(code, code.size - i - 1)
      break
    end
  end
  puts "Fixed code: #{code}"
  fixed_word = calc_difference(code, mod(code, POLYNOM))
  fixed_word = fixed_word[0..(CODE_WORD_LENGTH - WORD_LENGTH + 1)]
  puts "Fixed word: #{fixed_word}"
end