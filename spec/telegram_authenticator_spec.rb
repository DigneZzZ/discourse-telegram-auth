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
end
