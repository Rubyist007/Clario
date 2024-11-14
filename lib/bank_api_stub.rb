class BankApiStub
  def self.charge(amount)
    amount < 100 ? "success" : "insufficient funds"
  end
end
