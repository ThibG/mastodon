require 'rails_helper'

RSpec.describe BlockService, type: :service do
  let(:sender) { Fabricate(:account, username: 'alice') }

  subject { BlockService.new }

  context 'not stealth' do
    describe 'local' do
      let(:bob) { Fabricate(:user, email: 'bob@example.com', account: Fabricate(:account, username: 'bob')).account }

      before do
        subject.call(sender, bob)
      end

      it 'creates a blocking relation' do
        expect(sender.blocking?(bob)).to be true
      end
    end

    describe 'remote OStatus' do
      let(:bob) { Fabricate(:user, email: 'bob@example.com', account: Fabricate(:account, username: 'bob', domain: 'example.com', salmon_url: 'http://salmon.example.com')).account }

      before do
        stub_request(:post, "http://salmon.example.com/").to_return(:status => 200, :body => "", :headers => {})
        subject.call(sender, bob)
      end

      it 'creates a blocking relation' do
        expect(sender.blocking?(bob)).to be true
      end
    end

    describe 'remote ActivityPub' do
      let(:bob) { Fabricate(:user, email: 'bob@example.com', account: Fabricate(:account, username: 'bob', protocol: :activitypub, domain: 'example.com', inbox_url: 'http://example.com/inbox')).account }

      before do
        stub_request(:post, 'http://example.com/inbox').to_return(status: 200)
        subject.call(sender, bob)
      end

      it 'creates a blocking relation' do
        expect(sender.blocking?(bob)).to be true
      end

      it 'sends a block activity' do
        expect(a_request(:post, 'http://example.com/inbox')).to have_been_made.once
      end
    end
  end

  context 'stealth' do
    describe 'local' do
      let(:bob) { Fabricate(:user, email: 'bob@example.com', account: Fabricate(:account, username: 'bob')).account }

      before do
        subject.call(sender, bob, stealth: true)
      end

      it 'creates a blocking relation' do
        expect(sender.blocking?(bob)).to be true
      end
    end

    describe 'remote ActivityPub' do
      let(:bob) { Fabricate(:user, email: 'bob@example.com', account: Fabricate(:account, username: 'bob', protocol: :activitypub, domain: 'example.com', inbox_url: 'http://example.com/inbox')).account }

      before do
        stub_request(:post, 'http://example.com/inbox').to_return(status: 200)
        subject.call(sender, bob, stealth: true)
      end

      it 'creates a blocking relation' do
        expect(sender.blocking?(bob)).to be true
      end

      it 'does not send a block activity' do
        expect(a_request(:post, 'http://example.com/inbox')).not_to have_been_made
      end
    end
  end
end
