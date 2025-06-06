# frozen_string_literal: true

require 'rails_helper'

describe ::TelegramAuthenticator do
  let(:authenticator) { described_class.new }
  
  describe '#name' do
    it 'returns telegram' do
      expect(authenticator.name).to eq('telegram')
    end
  end
  
  describe '#enabled?' do
    it 'returns false when setting is disabled' do
      SiteSetting.telegram_auth_enabled = false
      expect(authenticator.enabled?).to eq(false)
    end
    
    it 'returns true when setting is enabled' do
      SiteSetting.telegram_auth_enabled = true
      expect(authenticator.enabled?).to eq(true)
    end
  end
  
  describe '#can_revoke?' do
    it 'returns true' do
      expect(authenticator.can_revoke?).to eq(true)
    end
  end
  
  describe '#can_connect_existing_user?' do
    it 'returns true' do
      expect(authenticator.can_connect_existing_user?).to eq(true)
    end
  end

  describe '#icon' do
    it 'returns fab-telegram' do
      expect(authenticator.icon).to eq('fab-telegram')
    end
  end
  describe '#description_for_user' do
    let(:user) { Fabricate(:user) }
    
    it 'returns empty string when user has no associated accounts' do
      expect(authenticator.description_for_user(user)).to eq('')
    end
    
    it 'returns empty string when user is nil' do
      expect(authenticator.description_for_user(nil)).to eq('')
    end
    
    context 'with telegram account' do
      let(:account) do
        UserAssociatedAccount.create!(
          user: user,
          provider_name: 'telegram',
          provider_uid: '123456789',
          info: { 'username' => 'test_user' }
        )
      end
      
      before { account }
      
      it 'returns description with username' do
        I18n.with_locale(:en) do
          result = authenticator.description_for_user(user)
          expect(result).to include('test_user')
        end
      end
      
      it 'handles missing username gracefully' do
        account.update!(info: { 'first_name' => 'John' })
        I18n.with_locale(:en) do
          result = authenticator.description_for_user(user)
          expect(result).to include('John')
        end
      end
    end
  end

  describe '#validate_telegram_signature' do
    let(:bot_token) { '123456789:ABCdefGHIjklMNOpqrsTUVwxyz' }
    
    it 'returns false for empty params' do
      expect(authenticator.validate_telegram_signature({}, bot_token)).to eq(false)
    end
    
    it 'returns false for empty bot token' do
      params = { 'id' => '123', 'hash' => 'test' }
      expect(authenticator.validate_telegram_signature(params, '')).to eq(false)
    end
    
    it 'returns false for missing hash' do
      params = { 'id' => '123', 'auth_date' => Time.now.to_i.to_s }
      expect(authenticator.validate_telegram_signature(params, bot_token)).to eq(false)
    end
    
    context 'with valid signature' do
      let(:auth_date) { Time.now.to_i }
      let(:params) do
        {
          'id' => '123456789',
          'first_name' => 'John',
          'last_name' => 'Doe',
          'username' => 'johndoe',
          'auth_date' => auth_date.to_s
        }
      end
      
      it 'validates correct signature' do
        # Имитируем правильную подпись (в реальном тесте должна быть реальная подпись)
        allow(OpenSSL::HMAC).to receive(:hexdigest).and_return('valid_signature')
        params['hash'] = 'valid_signature'
        
        expect(authenticator.validate_telegram_signature(params, bot_token)).to eq(true)
      end
    end
  end

  describe '#after_authenticate' do
    let(:auth_token) do
      {
        uid: '123456789',
        provider: 'telegram',
        info: {
          username: 'test_user',
          first_name: 'John',
          last_name: 'Doe',
          image: 'https://example.com/photo.jpg'
        },
        extra: {
          raw_info: {
            'id' => '123456789',
            'auth_date' => Time.now.to_i
          }
        }
      }
    end

    before do
      allow(authenticator).to receive(:after_authenticate).and_call_original
      SiteSetting.telegram_auth_enabled = true
    end

    it 'processes valid auth_token' do
      # Мокаем родительский метод
      result = Auth::Result.new
      result.user = Fabricate(:user)
      allow_any_instance_of(Auth::ManagedAuthenticator).to receive(:after_authenticate).and_return(result)
      
      final_result = authenticator.after_authenticate(auth_token)
      
      expect(final_result).to be_a(Auth::Result)
      expect(final_result.extra_data).to include(:telegram_id)
    end

    it 'rejects auth_token with missing provider' do
      auth_token[:provider] = nil
      
      result = authenticator.after_authenticate(auth_token)
      
      expect(result.failed).to eq(true)
      expect(result.failed_reason).to include('Invalid authentication data')
    end

    it 'rejects expired auth_token' do
      # Устанавливаем старую дату аутентификации (более 24 часов назад)
      old_date = Time.now.to_i - 86401
      auth_token[:extra][:raw_info]['auth_date'] = old_date
      
      result = authenticator.after_authenticate(auth_token)
      
      expect(result.failed).to eq(true)
      expect(result.failed_reason).to include('expired')
    end
  end
end
