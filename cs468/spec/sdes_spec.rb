require 'sdes'

describe 'Input of files for processing' do
  
  before(:each) do
    @input = SDES::Input.new('spec/plain-test.txt')
  end
  
  it 'should parse an encrypted file' do
    @input.should_not be_nil
  end
  
  it 'should have the file name' do
    @input.file_name.should eql("plain-test.txt")
  end
  
  it 'should have the student name' do
    @input.student_name.should eql("Name of Student")
  end
  
  it 'should want to be encrypted' do
    @input.mode.should eql("E")
    @input.encrypt?.should be_true
  end
  
  it 'should have a key' do
    @input.key.should eql("1100100001")
  end
  
  it 'should have content' do
    @input.content.should eql("Technology is a way of organizing the universe so that man doesn't have to experience it.\n")
  end
  
  it 'should support encryption of the file' do
    @input.should respond_to(:encrypt)
  end
  
  it 'should encrypt using the SDES::Utility' do
    SDES::Utility.should_receive(:encrypt).with(@input.content, @input.key)
    @input.encrypt
  end
  
end

describe 'Input file for decryption processing' do

  before(:each) do
    @input = SDES::Input.new('spec/testcrypt-17.txt')
  end

  it 'should support decrypting of the file' do
    @input.should respond_to(:decrypt)
  end
  
  it 'should decrypt using the SDES::Utility' do
    SDES::Utility.should_receive(:decrypt).with(@input.content, @input.key)
    @input.decrypt
  end
end

describe 'Decryption' do
  
  before(:each) do
    @plain_text = "Technology is a way of organizing the universe so that man doesn't have to experience it.\n"
    @cipher_text = "110001011101101110110101010001111100011111111110110001101111111011010000110100110010100101001100000101100010100101011110001010010111001101011110110100110010100111111110101010010010100111111110001001101101000001011110110001110100110011001001010011001100011111010000001010010110100101000111110110110010100101001010110001110100110010100111110110110010011000010110110110110010100100010110111111100010100101101001010001110101111001101001001010010000110101011110110001110010100111111100111111101101101100010110110001110100010001101001001010010100011101011110101001111101101100101001011010011111111000101001110110110000011100101000110110110010011001001100110110111100011110110101110110110010100101001100011010010001011111111010"
    @key = "1100100001"
  end
  
  it 'should encrypt' do
    SDES::Utility.encrypt(@plain_text, @key).should eql(@cipher_text)
  end

  it 'should decrypt' do
    SDES::Utility.decrypt(@cipher_text, @key).should eql(@plain_text) 
  end
  
  it 'should encrypt and decrypt something' do
    key = "1010101010"
    original_text = "Attack at dawn!"
    cipher_text = SDES::Utility.encrypt(original_text, key)
    SDES::Utility.decrypt(cipher_text, key).should eql(original_text)
  end

end

describe 'Binary/Decimal conversion' do
  
  it 'should convert decimal to binary' do
    SDES::Utility.bin_to_dec("0").should eql(0)
    SDES::Utility.bin_to_dec("1").should eql(1)
    SDES::Utility.bin_to_dec("10").should eql(2)
  end
  
  it 'should convert binary to decimal' do
    0.bin(4).should eql("0000")
    1.bin(4).should eql("0001")
    2.bin(4).should eql("0010")
    4.bin(4).should eql("0100")
    8.bin(4).should eql("1000")
  end
end

describe 'Flip' do
  
  it 'Basic flipping works' do
    SDES::Utility.flip(%q(12345678)).should eql(%q(56781234))
  end
  
end

describe 'Permutation' do
  
  it 'should support permutation' do
    SDES::Utility.should respond_to(:permute)
  end
  
  it 'should perform basic permutation' do
    map = %w(3 2 1)
    values = "abc"
    
    SDES::Utility.permute(map, values).should eql(values.reverse)
  end
  
  it 'should work when applying S-SDES initial and final permutation' do
    before_p =%q(abcdefgh)
    after_p  =%q(bfcadheg)
    SDES::Utility.permute(SDES::Initial, before_p).should eql(after_p)
    SDES::Utility.permute(SDES::Final, after_p).should eql(before_p)
  end
  
end

describe 'Expansion' do
  it 'should support expansion' do
    SDES::Utility.should respond_to(:expand)
  end
  
  it 'should perform basic expansion' do
    table  = %w(4 1 2 3 4 1)
    result = %q(dabcda)
    values = %q(abcd)
    
    SDES::Utility.expand(table, values).should eql(result)
  end
end

describe 'Substitution' do
  it 'should support substitution' do
    SDES::Utility.should respond_to(:substitute)
  end
  
  it 'should perform basic substitution' do
    s0 = SDES::S0
    s1 = SDES::S1
    
    SDES::Utility.substitute("0000",s0).should eql(1)
    SDES::Utility.substitute("0001",s0).should eql(3)
    SDES::Utility.substitute("1111",s0).should eql(2)
    
    SDES::Utility.substitute("0000",s1).should eql(0)
    SDES::Utility.substitute("0001",s1).should eql(2)
    SDES::Utility.substitute("1111",s1).should eql(3)
  end
  
  it 'should calculate the row using the first and last char' do
    # Testing the row/col values that should be generated and
    # not the values that are in individual mappings.
    s0 = SDES::S0
    m1 = Proc.new { |row, column| [row, column] }
    
    SDES::Utility.substitute("0000",s0,&m1).should eql([0,0])
    SDES::Utility.substitute("0001",s0,&m1).should eql([1,0])
    SDES::Utility.substitute("0010",s0,&m1).should eql([0,1])
    SDES::Utility.substitute("0011",s0,&m1).should eql([1,1])
    SDES::Utility.substitute("0100",s0,&m1).should eql([0,2])
    SDES::Utility.substitute("0101",s0,&m1).should eql([1,2])
    SDES::Utility.substitute("0110",s0,&m1).should eql([0,3])
    SDES::Utility.substitute("1000",s0,&m1).should eql([2,0])
    SDES::Utility.substitute("1001",s0,&m1).should eql([3,0])
    SDES::Utility.substitute("1010",s0,&m1).should eql([2,1])
    SDES::Utility.substitute("1011",s0,&m1).should eql([3,1])
    SDES::Utility.substitute("1100",s0,&m1).should eql([2,2])
    SDES::Utility.substitute("1101",s0,&m1).should eql([3,2])
    SDES::Utility.substitute("1110",s0,&m1).should eql([2,3])
    SDES::Utility.substitute("1111",s0,&m1).should eql([3,3])
  end
 
end

describe 'Circular shifting' do
  
  it 'should rotate left correctly (with value of 1)' do
    SDES::Utility.rotate_left(1,1).should eql(2)
    SDES::Utility.rotate_left(1,2).should eql(4)
    SDES::Utility.rotate_left(1,3).should eql(8)
    SDES::Utility.rotate_left(1,4).should eql(16)
    SDES::Utility.rotate_left(1,5).should eql(32)
    SDES::Utility.rotate_left(1,6).should eql(64)
    SDES::Utility.rotate_left(1,7).should eql(128)
    SDES::Utility.rotate_left(1,8).should eql(1)
  end
  
  it 'should rotate left correctly' do
    SDES::Utility.rotate_left(255, 1).should eql(255)
    SDES::Utility.rotate_left(127, 1).should eql(255-1)
    SDES::Utility.rotate_left(63,  2).should eql(255-3)
  end
  
  it 'should rotate right correctly' do
    SDES::Utility.rotate_right(2,1).should eql(1)
    SDES::Utility.rotate_right(255,1).should eql(255)
  end
  
  it 'should rotate a five bit number correctly' do
    x = SDES::Utility.bin_to_dec("1100")
    y = SDES::Utility.rotate_left(x,2,4)
    z = SDES::Utility.dec_to_bin(y)
    z.should eql("11")
  end
  
end

describe 'Encryption' do
  
  it 'should encrypt a single character with a key correctly' do
    input = "Tech"
    key = "1100100001"
    
    encrypted = SDES::Utility.encrypt(input, key)
    encrypted.length.should eql(32)
    encrypted.should eql("11000101110110111011010101000111")
  end
  
end

describe 'Mangling (f function)' do

  it 'should fk' do
    pending
  end
  
  it 'should f' do
    b = "0000"
    k = "11001010"
    SDES::Utility.f(b,k).should eql("1000")
  end

end

describe 'Generating one key from another' do
  it 'should generate a pair' do
    keys = SDES::Key.subkey("1010000010")
    keys[0].should eql("10100100")
    keys[1].should eql("01000011")
  end
  
  it 'should permute using P10 correctly' do
    SDES::Key._p10("1010000010").should eql("1000001100")
  end
  
  it 'should split correctly' do
    SDES::Key._hi("1000001100").should eql("10000")
    SDES::Key._lo("1000001100").should eql("01100")
  end
  
  it 'should left shift by 1 correctly' do
    SDES::Key._ls1("10000").should eql("00001")
    SDES::Key._ls1("01100").should eql("11000")
  end
  
  it 'should left shift by 3 correctly' do
    SDES::Key._ls3("10000").should eql("00100")
    SDES::Key._ls3("01100").should eql("00011")
  end
  
  it 'should permute using P8 correctly' do
    SDES::Key._p8("0000111000").should eql("10100100")
    SDES::Key._p8("0010000011").should eql("01000011")
  end
  
end

describe 'Array extensions' do
  it 'should convert a set of ints to a string' do
    [97,98,99].as_str.should eql("abc")
  end
  
  it 'should convert a set of chars to a string' do
    ['a','b','c'].as_str.should eql("abc")
  end
end